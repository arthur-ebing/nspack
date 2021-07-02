# frozen_string_literal: true

module MasterfilesApp
  class InspectionFailureReasonInteractor < BaseInteractor
    def create_inspection_failure_reason(params)
      res = validate_inspection_failure_reason_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_inspection_failure_reason(res)
        log_status(:inspection_failure_reasons, id, 'CREATED')
        log_transaction
      end
      instance = inspection_failure_reason(id)
      success_response("Created inspection failure reason #{instance.failure_reason}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { failure_reason: ['This inspection failure reason already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_inspection_failure_reason(id, params)
      res = validate_inspection_failure_reason_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inspection_failure_reason(id, res)
        log_transaction
      end
      instance = inspection_failure_reason(id)
      success_response("Updated inspection failure reason #{instance.failure_reason}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inspection_failure_reason(id) # rubocop:disable Metrics/AbcSize
      name = inspection_failure_reason(id).failure_reason
      repo.transaction do
        repo.delete_inspection_failure_reason(id)
        log_status(:inspection_failure_reasons, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inspection failure reason #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete inspection failure reason. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::InspectionFailureReason.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QualityRepo.new
    end

    def inspection_failure_reason(id)
      repo.find_inspection_failure_reason(id)
    end

    def validate_inspection_failure_reason_params(params)
      InspectionFailureReasonSchema.call(params)
    end
  end
end
