# frozen_string_literal: true

module MasterfilesApp
  class EmploymentTypeInteractor < BaseInteractor
    def create_employment_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_employment_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_employment_type(res)
        log_status(:employment_types, id, 'CREATED')
        log_transaction
      end
      instance = employment_type(id)
      success_response("Created employment type #{instance.employment_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { employment_type_code: ['This employment type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_employment_type(id, params)
      res = validate_employment_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_employment_type(id, res)
        log_transaction
      end
      instance = employment_type(id)
      success_response("Updated employment type #{instance.employment_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_employment_type(id)
      name = employment_type(id).employment_type_code
      repo.transaction do
        repo.delete_employment_type(id)
        log_status(:employment_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted employment type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::EmploymentType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= HumanResourcesRepo.new
    end

    def employment_type(id)
      repo.find_employment_type(id)
    end

    def validate_employment_type_params(params)
      EmploymentTypeSchema.call(params)
    end
  end
end
