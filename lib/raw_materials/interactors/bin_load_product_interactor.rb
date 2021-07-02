# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadProductInteractor < BaseInteractor
    def create_bin_load_product(params)
      res = validate_bin_load_product_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_bin_load_product(res)
        log_status(:bin_load_products, id, 'CREATED')
        log_transaction
      end
      instance = bin_load_product(id)
      success_response("Created bin load product #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This bin load product already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_bin_load_product(id, params)
      res = validate_bin_load_product_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_bin_load_product(id, res)
        log_transaction
      end
      instance = bin_load_product(id)
      success_response("Updated bin load product #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_bin_load_product(id)
      instance = bin_load_product(id)
      bin_ids = repo.select_values(:rmt_bins, :id, bin_load_product_id: id)

      repo.transaction do
        repo.unallocate_bins(bin_ids, @user)

        repo.delete_bin_load_product(id)
        log_status(:bin_load_products, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted bin load product #{instance.product_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_bin_load_product(id, params, scanned = false) # rubocop:disable Metrics/AbcSize
      res = AllocateBinLoadProductSchema.call(params)
      return validation_failed_response(res) if res.failure?

      new_allocation = res.to_h[:bin_ids]
      current_allocation = repo.select_values(:rmt_bins, :id, bin_load_product_id: id)

      repo.transaction do
        repo.unallocate_bins(current_allocation - new_allocation, @user) unless scanned
        repo.allocate_bins(id, new_allocation - current_allocation, @user)

        log_transaction
      end
      instance = bin_load_product(id)
      success_response('Allocated to Bin Load', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_bin(bin_number)
      bin = RmtDeliveryRepo.new.find_rmt_bin_stock(bin_number)
      return failed_response("Scanned Bin:#{bin_number} is not in stock") unless bin
      return failed_response("Scanned Bin:#{bin_number} has been tipped") if bin[:bin_tipped]

      success_response('Valid Bin Scanned',
                       bin)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::BinLoadProduct.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def allocate_scanned_bin_load_product(bin_load_product_id, params)
      res = validate_scanned_bins(bin_load_product_id, params)
      return validation_failed_response(res) unless res.success

      allocate_bin_load_product(bin_load_product_id, { bin_ids: res.instance[:bin_ids] }, true)
    end

    private

    def repo
      @repo ||= BinLoadRepo.new
    end

    def bin_load_product(id)
      repo.find_bin_load_product_flat(id)
    end

    def validate_bin_load_product_params(params)
      BinLoadProductSchema.call(params)
    end

    def validate_scanned_bins(bin_load_product_id, params) # rubocop:disable Metrics/AbcSize
      bin_ids = params[:bin_ids].split(/\n|,/).map(&:strip).reject(&:empty?)
      bin_ids = bin_ids.map { |x| x.gsub(/['"]/, '') }

      invalid_bin_ids = bin_ids.reject { |x| x.match(/\A\d+\Z/) }
      return OpenStruct.new(success: false, messages: { bin_ids: ["#{invalid_bin_ids.join(', ')} must be numeric"] }, bin_ids: bin_ids) unless invalid_bin_ids.nil_or_empty?

      existing_bin_ids = repo.rmt_bins_exists?(bin_ids)
      missing_bin_ids = (bin_ids.map(&:to_i) - existing_bin_ids)
      return OpenStruct.new(success: false, messages: { bin_ids: ["#{missing_bin_ids.join(', ')} doesn't exist"] }, bin_ids: bin_ids) unless missing_bin_ids.nil_or_empty?

      bin_load_bin_ids = repo.rmt_bins_matching_bin_load(:bin_id, bin_load_product_id: bin_load_product_id, bin_id: bin_ids)
      mismatch_load_bin_ids = (existing_bin_ids - bin_load_bin_ids)
      return OpenStruct.new(success: false, messages: { bin_ids: ["#{mismatch_load_bin_ids.join(', ')} doesn't match bin load"] }, bin_ids: bin_ids) unless mismatch_load_bin_ids.nil_or_empty?

      OpenStruct.new(success: true, instance: { bin_ids: bin_ids })
    end
  end
end
