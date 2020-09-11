# frozen_string_literal: true

module MasterfilesApp
  class PmTypeInteractor < BaseInteractor
    def create_pm_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_pm_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pm_type(res)
        log_status('pm_types', id, 'CREATED')
        log_transaction
      end
      instance = pm_type(id)
      success_response("Created pm type #{instance.pm_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { pm_type_code: ['This pm type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pm_type(id, params)
      res = validate_pm_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pm_type(id, res)
        log_transaction
      end
      instance = pm_type(id)
      success_response("Updated pm type #{instance.pm_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pm_type(id)
      name = pm_type(id).pm_type_code
      repo.transaction do
        repo.delete_pm_type(id)
        log_status('pm_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pm type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PmType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= BomsRepo.new
    end

    def pm_type(id)
      repo.find_pm_type(id)
    end

    def validate_pm_type_params(params)
      PmTypeSchema.call(params)
    end
  end
end
