# frozen_string_literal: true

module MasterfilesApp
  class RmtContainerTypeInteractor < BaseInteractor
    def repo
      @repo ||= RmtContainerTypeRepo.new
    end

    def rmt_container_type(id)
      repo.find_rmt_container_type(id)
    end

    def validate_rmt_container_type_params(params)
      RmtContainerTypeSchema.call(params)
    end

    def create_rmt_container_type(params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_container_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_container_type(res)
        log_status('rmt_container_types', id, 'CREATED')
        log_transaction
      end
      instance = rmt_container_type(id)
      success_response("Created rmt container type #{instance.container_type_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { container_type_code: ['This rmt container type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_container_type(id, params)
      res = validate_rmt_container_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_container_type(id, res)
        log_transaction
      end
      instance = rmt_container_type(id)
      success_response("Updated rmt container type #{instance.container_type_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_container_type(id)
      name = rmt_container_type(id).container_type_code
      repo.transaction do
        repo.delete_rmt_container_type(id)
        log_status('rmt_container_types', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt container type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_rmt_container_type(id, params)
    #   res = complete_a_record(:rmt_container_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, rmt_container_type(id))
    #   else
    #     failed_response(res.message, rmt_container_type(id))
    #   end
    # end

    # def reopen_a_rmt_container_type(id, params)
    #   res = reopen_a_record(:rmt_container_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, rmt_container_type(id))
    #   else
    #     failed_response(res.message, rmt_container_type(id))
    #   end
    # end

    # def approve_or_reject_a_rmt_container_type(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:rmt_container_types, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:rmt_container_types, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, rmt_container_type(id))
    #   else
    #     failed_response(res.message, rmt_container_type(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtContainerType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end
  end
end
