# frozen_string_literal: true

module MasterfilesApp
  class TreatmentInteractor < BaseInteractor
    def create_treatment(params) # rubocop:disable Metrics/AbcSize
      res = validate_treatment_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_treatment(res)
        log_status('treatments', id, 'CREATED')
        log_transaction
      end
      instance = treatment(id)
      success_response("Created treatment #{instance.treatment_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { treatment_code: ['This treatment already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_treatment(id, params)
      res = validate_treatment_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_treatment(id, res)
        log_transaction
      end
      instance = treatment(id)
      success_response("Updated treatment #{instance.treatment_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_treatment(id)
      name = treatment(id).treatment_code
      repo.transaction do
        repo.delete_treatment(id)
        log_status('treatments', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted treatment #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Treatment.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= FruitRepo.new
    end

    def treatment(id)
      repo.find_treatment(id)
    end

    def validate_treatment_params(params)
      TreatmentSchema.call(params)
    end
  end
end
