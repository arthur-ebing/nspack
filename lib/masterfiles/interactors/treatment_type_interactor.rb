# frozen_string_literal: true

module MasterfilesApp
  class TreatmentTypeInteractor < BaseInteractor
    def create_treatment_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_treatment_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_treatment_type(res)
        log_status('treatment_types', id, 'CREATED')
        log_transaction
      end
      instance = treatment_type(id)
      success_response("Created treatment type #{instance.treatment_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { treatment_type_code: ['This treatment type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_treatment_type(id, params)
      res = validate_treatment_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_treatment_type(id, res)
        log_transaction
      end
      instance = treatment_type(id)
      success_response("Updated treatment type #{instance.treatment_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_treatment_type(id)
      name = treatment_type(id).treatment_type_code
      repo.transaction do
        repo.delete_treatment_type(id)
        log_status('treatment_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted treatment type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::TreatmentType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FruitRepo.new
    end

    def treatment_type(id)
      repo.find_treatment_type(id)
    end

    def validate_treatment_type_params(params)
      TreatmentTypeSchema.call(params)
    end
  end
end
