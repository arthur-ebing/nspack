# frozen_string_literal: true

module MasterfilesApp
  class InspectionFailureReasonInteractor < BaseInteractor
    def create_inspection_failure_reason(params) # rubocop:disable Metrics/AbcSize
      res = validate_inspection_failure_reason_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_inspection_failure_reason(res)
        log_status('inspection_failure_reasons', id, 'CREATED')
        log_transaction
      end
      instance = inspection_failure_reason(id)
      success_response("Created inspection failure reason #{instance.failure_reason}",
                       instance)
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
      success_response("Updated inspection failure reason #{instance.failure_reason}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inspection_failure_reason(id)
      name = inspection_failure_reason(id).failure_reason
      repo.transaction do
        repo.delete_inspection_failure_reason(id)
        log_status('inspection_failure_reasons', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inspection failure reason #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_inspection_failure_reason(id, params)
    #   res = complete_a_record(:inspection_failure_reasons, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, inspection_failure_reason(id))
    #   else
    #     failed_response(res.message, inspection_failure_reason(id))
    #   end
    # end

    # def reopen_a_inspection_failure_reason(id, params)
    #   res = reopen_a_record(:inspection_failure_reasons, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, inspection_failure_reason(id))
    #   else
    #     failed_response(res.message, inspection_failure_reason(id))
    #   end
    # end

    # def approve_or_reject_a_inspection_failure_reason(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:inspection_failure_reasons, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:inspection_failure_reasons, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, inspection_failure_reason(id))
    #   else
    #     failed_response(res.message, inspection_failure_reason(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::InspectionFailureReason.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= InspectionFailureReasonRepo.new
    end

    def inspection_failure_reason(id)
      repo.find_inspection_failure_reason(id)
    end

    def validate_inspection_failure_reason_params(params)
      InspectionFailureReasonSchema.call(params)
    end
  end
end
