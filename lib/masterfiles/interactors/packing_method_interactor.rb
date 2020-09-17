# frozen_string_literal: true

module MasterfilesApp
  class PackingMethodInteractor < BaseInteractor
    def create_packing_method(params)  # rubocop:disable Metrics/AbcSize
      res = validate_packing_method_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_packing_method(res)
        log_status(:packing_methods, id, 'CREATED')
        log_transaction
      end
      instance = packing_method(id)
      success_response("Created packing method #{instance.packing_method_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { packing_method_code: ['This packing method already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_packing_method(id, params)
      res = validate_packing_method_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_packing_method(id, res)
        log_transaction
      end
      instance = packing_method(id)
      success_response("Updated packing method #{instance.packing_method_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_packing_method(id)
      name = packing_method(id).packing_method_code
      repo.transaction do
        repo.delete_packing_method(id)
        log_status(:packing_methods, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted packing method #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PackingMethod.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PackagingRepo.new
    end

    def packing_method(id)
      repo.find_packing_method(id)
    end

    def validate_packing_method_params(params)
      PackingMethodSchema.call(params)
    end
  end
end
