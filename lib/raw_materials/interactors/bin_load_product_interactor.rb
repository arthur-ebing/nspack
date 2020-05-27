# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadProductInteractor < BaseInteractor
    def create_bin_load_product(params) # rubocop:disable Metrics/AbcSize
      res = validate_bin_load_product_params(params)
      return validation_failed_response(res) unless res.messages.empty?

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
      return validation_failed_response(res) unless res.messages.empty?

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
      name = bin_load_product(id).id
      repo.transaction do
        repo.delete_bin_load_product(id)
        log_status(:bin_load_products, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted bin load product #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def allocate_bin_load_product(id, params) # rubocop:disable Metrics/AbcSize
      res = AllocateBinLoadProductSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      bin_ids = res.to_h[:bin_ids]
      repo.transaction do
        unallocate_ids = repo.select_values(:rmt_bins, :id, bin_load_product_id: id) - bin_ids

        repo.unallocate_bin_load(unallocate_ids, @user)
        repo.allocate_bin_load(id, bin_ids, @user)

        log_transaction
      end
      success_response('Allocated to Bin Load')
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
  end
end
