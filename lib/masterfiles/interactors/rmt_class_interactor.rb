# frozen_string_literal: true

module MasterfilesApp
  class RmtClassInteractor < BaseInteractor
    def repo
      @repo ||= FruitRepo.new
    end

    def rmt_class(id)
      repo.find_rmt_class(id)
    end

    def validate_rmt_class_params(params)
      RmtClassSchema.call(params)
    end

    def create_rmt_class(params) # rubocop:disable Metrics/AbcSize
      res = validate_rmt_class_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_rmt_class(res)
        log_status('rmt_classes', id, 'CREATED')
        log_transaction
      end
      instance = rmt_class(id)
      success_response("Created rmt class #{instance.rmt_class_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { rmt_class_code: ['This rmt class already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_rmt_class(id, params)
      res = validate_rmt_class_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_rmt_class(id, res)
        log_transaction
      end
      instance = rmt_class(id)
      success_response("Updated rmt class #{instance.rmt_class_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_rmt_class(id)
      name = rmt_class(id).rmt_class_code
      repo.transaction do
        repo.delete_rmt_class(id)
        log_status('rmt_classes', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted rmt class #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    # def complete_a_rmt_class(id, params)
    #   res = complete_a_record(:rmt_classes, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, rmt_class(id))
    #   else
    #     failed_response(res.message, rmt_class(id))
    #   end
    # end

    # def reopen_a_rmt_class(id, params)
    #   res = reopen_a_record(:rmt_classes, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, rmt_class(id))
    #   else
    #     failed_response(res.message, rmt_class(id))
    #   end
    # end

    # def approve_or_reject_a_rmt_class(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:rmt_classes, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:rmt_classes, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, rmt_class(id))
    #   else
    #     failed_response(res.message, rmt_class(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::RmtClass.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end
  end
end
