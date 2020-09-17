# frozen_string_literal: true

module MasterfilesApp
  class InspectionFailureTypeInteractor < BaseInteractor
    def create_inspection_failure_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_inspection_failure_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_inspection_failure_type(res)
        log_status('inspection_failure_types', id, 'CREATED')
        log_transaction
      end
      instance = inspection_failure_type(id)
      success_response("Created inspection failure type #{instance.failure_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { failure_type_code: ['This inspection failure type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_inspection_failure_type(id, params)
      res = validate_inspection_failure_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inspection_failure_type(id, res)
        log_transaction
      end
      instance = inspection_failure_type(id)
      success_response("Updated inspection failure type #{instance.failure_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inspection_failure_type(id)
      name = inspection_failure_type(id).failure_type_code
      repo.transaction do
        repo.delete_inspection_failure_type(id)
        log_status('inspection_failure_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted inspection failure type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_inspection_failure_type(id, params)
    #   res = complete_a_record(:inspection_failure_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, inspection_failure_type(id))
    #   else
    #     failed_response(res.message, inspection_failure_type(id))
    #   end
    # end

    # def reopen_a_inspection_failure_type(id, params)
    #   res = reopen_a_record(:inspection_failure_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, inspection_failure_type(id))
    #   else
    #     failed_response(res.message, inspection_failure_type(id))
    #   end
    # end

    # def approve_or_reject_a_inspection_failure_type(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:inspection_failure_types, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:inspection_failure_types, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, inspection_failure_type(id))
    #   else
    #     failed_response(res.message, inspection_failure_type(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::InspectionFailureType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= InspectionFailureTypeRepo.new
    end

    def inspection_failure_type(id)
      repo.find_inspection_failure_type(id)
    end

    def validate_inspection_failure_type_params(params)
      InspectionFailureTypeSchema.call(params)
    end
  end
end
