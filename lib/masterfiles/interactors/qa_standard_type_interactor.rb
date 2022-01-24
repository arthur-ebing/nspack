# frozen_string_literal: true

module MasterfilesApp
  class QaStandardTypeInteractor < BaseInteractor
    def create_qa_standard_type(params)
      res = validate_qa_standard_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_qa_standard_type(res)
        log_status(:qa_standard_types, id, 'CREATED')
        log_transaction
      end
      instance = qa_standard_type(id)
      success_response("Created QA standard type #{instance.qa_standard_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { qa_standard_type_code: ['This QA standard type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qa_standard_type(id, params)
      res = validate_qa_standard_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qa_standard_type(id, res)
        log_transaction
      end
      instance = qa_standard_type(id)
      success_response("Updated QA standard type #{instance.qa_standard_type_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_qa_standard_type(id) # rubocop:disable Metrics/AbcSize
      name = qa_standard_type(id).qa_standard_type_code
      repo.transaction do
        repo.delete_qa_standard_type(id)
        log_status(:qa_standard_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted QA standard type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete QA standard type. It is still referenced#{e.message.partition('referenced').last}")
    end

    # def complete_a_qa_standard_type(id, params)
    #   res = complete_a_record(:qa_standard_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, qa_standard_type(id))
    #   else
    #     failed_response(res.message, qa_standard_type(id))
    #   end
    # end

    # def reopen_a_qa_standard_type(id, params)
    #   res = reopen_a_record(:qa_standard_types, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, qa_standard_type(id))
    #   else
    #     failed_response(res.message, qa_standard_type(id))
    #   end
    # end

    # def approve_or_reject_a_qa_standard_type(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:qa_standard_types, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:qa_standard_types, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, qa_standard_type(id))
    #   else
    #     failed_response(res.message, qa_standard_type(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::QaStandardType.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QaStandardTypeRepo.new
    end

    def qa_standard_type(id)
      repo.find_qa_standard_type(id)
    end

    def validate_qa_standard_type_params(params)
      QaStandardTypeSchema.call(params)
    end
  end
end
