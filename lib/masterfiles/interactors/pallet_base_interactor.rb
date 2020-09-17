# frozen_string_literal: true

module MasterfilesApp
  class PalletBaseInteractor < BaseInteractor
    def create_pallet_base(params) # rubocop:disable Metrics/AbcSize
      res = validate_pallet_base_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pallet_base(res)
        log_status('pallet_bases', id, 'CREATED')
        log_transaction
      end
      instance = pallet_base(id)
      success_response("Created pallet base #{instance.pallet_base_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { pallet_base_code: ['This pallet base already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallet_base(id, params)
      res = validate_pallet_base_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pallet_base(id, res)
        log_transaction
      end
      instance = pallet_base(id)
      success_response("Updated pallet base #{instance.pallet_base_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pallet_base(id)
      name = pallet_base(id).pallet_base_code
      repo.transaction do
        repo.delete_pallet_base(id)
        log_status('pallet_bases', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pallet base #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PalletBase.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PackagingRepo.new
    end

    def pallet_base(id)
      repo.find_pallet_base(id)
    end

    def validate_pallet_base_params(params)
      PalletBaseSchema.call(params)
    end
  end
end
