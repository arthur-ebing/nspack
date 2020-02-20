# frozen_string_literal: true

module ProductionApp
  class ShiftExceptionInteractor < BaseInteractor
    def create_shift_exception(parent_id, params) # rubocop:disable Metrics/AbcSize
      params[:shift_id] = parent_id
      res = validate_shift_exception_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_shift_exception(res)
        log_status(:shift_exceptions, id, 'CREATED')
        log_transaction
      end
      instance = shift_exception(id)
      success_response("Created shift exception #{instance.remarks}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { remarks: ['This shift exception already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_shift_exception(id, params)
      res = validate_shift_exception_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_shift_exception(id, res)
        log_transaction
      end
      instance = shift_exception(id)
      success_response("Updated shift exception #{instance.remarks}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_shift_exception(id)
      name = shift_exception(id).remarks
      repo.transaction do
        repo.delete_shift_exception(id)
        log_status(:shift_exceptions, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted shift exception #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_shift_exception(id, params)
    #   res = complete_a_record(:shift_exceptions, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, shift_exception(id))
    #   else
    #     failed_response(res.message, shift_exception(id))
    #   end
    # end

    # def reopen_a_shift_exception(id, params)
    #   res = reopen_a_record(:shift_exceptions, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, shift_exception(id))
    #   else
    #     failed_response(res.message, shift_exception(id))
    #   end
    # end

    # def approve_or_reject_a_shift_exception(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:shift_exceptions, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:shift_exceptions, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, shift_exception(id))
    #   else
    #     failed_response(res.message, shift_exception(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ShiftException.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= ProductionApp::HumanResourcesRepo.new
    end

    def shift_exception(id)
      repo.find_shift_exception(id)
    end

    def validate_shift_exception_params(params)
      ShiftExceptionSchema.call(params)
    end
  end
end
