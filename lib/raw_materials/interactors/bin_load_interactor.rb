# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_bin_load(params)
      res = validate_bin_load_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_bin_load(res)
        log_status(:bin_loads, id, 'CREATED')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Created Bin load: #{id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This bin load already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_bin_load(id, params)
      res = validate_bin_load_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_bin_load(id, res)
        log_transaction
      end
      instance = bin_load(id)
      success_response("Updated Bin load: #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_bin_load(id) # rubocop:disable Metrics/AbcSize
      check!(:delete, id)
      bin_load_product_ids = repo.select_values(:bin_load_products, :id, bin_load_id: id)

      repo.transaction do
        repo.delete(:bin_load_products, bin_load_product_ids)
        log_multiple_statuses(:bin_load_products, bin_load_product_ids, 'DELETED')

        repo.delete_bin_load(id)
        log_status(:bin_loads, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted Bin load: #{id}")
    rescue Sequel::ForeignKeyConstraintViolation => e
      failed_response("Unable to delete bin load. Still referenced #{e.message.partition('referenced').last}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def complete_bin_load(id)
      check!(:complete, id)
      params = { completed: true, completed_at: Time.now }
      repo.transaction do
        repo.update_bin_load(id, params)
        log_status(:bin_loads, id, 'COMPLETED')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Completed Bin load: #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def reopen_bin_load(id)
      check!(:reopen, id)
      repo.transaction do
        repo.update_bin_load(id, completed: false, completed_at: nil)
        log_status(:bin_loads, id, 'REOPENED')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Reopened Bin load: #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_and_ship_bin_load(id, product_bin) # rubocop:disable Metrics/AbcSize
      repo.transaction do
        bin_load_product_ids = repo.select_values(:bin_load_products, :id, bin_load_id: id)
        rmt_bin_ids = repo.select_values(:rmt_bins, :id, bin_load_product_id: bin_load_product_ids)
        repo.unallocate_bins(rmt_bin_ids, @user) unless rmt_bin_ids.empty?

        product_bin.each do |bin_load_product_id, bin_asset_number|
          rmt_bin_id = repo.select_values(:rmt_bins, :id, bin_asset_number: bin_asset_number)
          repo.allocate_bins(bin_load_product_id, rmt_bin_id, @user)
        end

        repo.ship_bin_load(id, @user, 'SHIPPED')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Shipped Bin load: #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unallocate_bin_load(id)
      check!(:reopen, id)
      bin_load_product_ids = repo.select_values(:bin_load_products, :id, bin_load_id: id)
      bin_ids = repo.select_values(:rmt_bins, :id, bin_load_product_id: bin_load_product_ids)
      repo.transaction do
        repo.unallocate_bins(bin_ids, @user)

        log_transaction
      end
      instance = bin_load(id)
      success_response("Unallocated pallets from Bin load: #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def ship_bin_load(id)
      check!(:ship, id)
      repo.transaction do
        repo.ship_bin_load(id, @user, 'SHIPPED MANUALLY')
        log_transaction
      end
      instance = bin_load(id)
      success_response("Shipped Bin load: #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def shipped_at_bin_load(id, params)
      repo.transaction do
        repo.update_bin_load(id, params)
        log_transaction
      end
      instance = bin_load(id)
      success_response("Updated Bin load: #{id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def unship_bin_load(id)
      check!(:unship, id)
      repo.transaction do
        repo.unship_bin_load(id, @user)
        log_transaction
      end
      instance = bin_load(id)
      success_response("Unshipped Bin load: #{id}", instance)
    rescue Sequel::UniqueConstraintViolation => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def send_hbs_edi(bin_load_id)
      EdiApp::SendEdiOut.call(AppConst::EDI_FLOW_HBS, nil, @user.user_name, bin_load_id, context: { fg_load: false })
    end

    def scan_bin_load(params) # rubocop:disable Metrics/AbcSize
      res = ScanBinLoadSchema.call(params)
      return validation_failed_response(res) if res.failure?

      id = params[:bin_load_id]
      check!(:allocate, id)

      products = repo.select_values(:bin_load_products, %i[id qty_bins], bin_load_id: id)
      products.each do |bin_load_product_id, qty_bins|
        qty_available = repo.rmt_bins_matching_bin_load(:bin_asset_number, bin_load_product_id: bin_load_product_id).count
        return failed_response("Bin load: #{id} - Insufficient bins available") if qty_available < qty_bins
      end
      instance = bin_load(id)
      success_response('Load valid', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def scan_bin_to_bin_load(params)
      res = ScanBinToBinLoadSchema.call(params)
      return validation_failed_response(res) if res.failure?

      bin_asset_number = params[:bin_asset_number]
      bin_id = repo.get_id(:rmt_bins, bin_asset_number: bin_asset_number)
      return failed_response "Bin:#{bin_asset_number} not in stock" if bin_id.nil?

      success_response('ok', bin_asset_number)
    end

    def stepper(step_key)
      @stepper ||= BinLoadStep.new(step_key, @user, @context.request_ip)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::BinLoad.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def rmt_bins_matching_bin_load(column, args)
      repo.rmt_bins_matching_bin_load(column, args)
    end

    private

    def repo
      @repo ||= BinLoadRepo.new
    end

    def bin_load(id)
      repo.find_bin_load_flat(id)
    end

    def validate_bin_load_params(params)
      BinLoadSchema.call(params)
    end

    def check!(task, id = nil)
      res = TaskPermissionCheck::BinLoad.call(task, id)
      raise Crossbeams::InfoError, res.message unless res.success
    end
  end
end
