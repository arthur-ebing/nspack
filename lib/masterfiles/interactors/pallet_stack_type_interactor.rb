# frozen_string_literal: true

module MasterfilesApp
  class PalletStackTypeInteractor < BaseInteractor
    def create_pallet_stack_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_pallet_stack_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pallet_stack_type(res)
        log_status('pallet_stack_types', id, 'CREATED')
        log_transaction
      end
      instance = pallet_stack_type(id)
      success_response("Created pallet stack type #{instance.stack_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { stack_type_code: ['This pallet stack type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallet_stack_type(id, params)
      res = validate_pallet_stack_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pallet_stack_type(id, res)
        log_transaction
      end
      instance = pallet_stack_type(id)
      success_response("Updated pallet stack type #{instance.stack_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pallet_stack_type(id)
      name = pallet_stack_type(id).stack_type_code
      repo.transaction do
        repo.delete_pallet_stack_type(id)
        log_status('pallet_stack_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pallet stack type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PalletStackType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PackagingRepo.new
    end

    def pallet_stack_type(id)
      repo.find_pallet_stack_type(id)
    end

    def validate_pallet_stack_type_params(params)
      PalletStackTypeSchema.call(params)
    end
  end
end
