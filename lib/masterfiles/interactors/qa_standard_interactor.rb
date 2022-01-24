# frozen_string_literal: true

module MasterfilesApp
  class QaStandardInteractor < BaseInteractor
    def create_qa_standard(params)
      res = validate_qa_standard_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_qa_standard(res)
        log_status(:qa_standards, id, 'CREATED')
        log_transaction
      end
      instance = qa_standard(id)
      success_response("Created QA standard #{instance.qa_standard_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { qa_standard_name: ['This QA standard already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qa_standard(id, params)
      res = validate_qa_standard_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qa_standard(id, res)
        log_transaction
      end
      instance = qa_standard(id)
      success_response("Updated QA standard #{instance.qa_standard_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_qa_standard(id) # rubocop:disable Metrics/AbcSize
      name = qa_standard(id).qa_standard_name
      repo.transaction do
        repo.delete_qa_standard(id)
        log_status(:qa_standards, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted QA standard #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete QA standard. It is still referenced#{e.message.partition('referenced').last}")
    end

    # def complete_a_qa_standard(id, params)
    #   res = complete_a_record(:qa_standards, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, qa_standard(id))
    #   else
    #     failed_response(res.message, qa_standard(id))
    #   end
    # end

    # def reopen_a_qa_standard(id, params)
    #   res = reopen_a_record(:qa_standards, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, qa_standard(id))
    #   else
    #     failed_response(res.message, qa_standard(id))
    #   end
    # end

    # def approve_or_reject_a_qa_standard(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:qa_standards, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:qa_standards, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, qa_standard(id))
    #   else
    #     failed_response(res.message, qa_standard(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::QaStandard.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QaStandardRepo.new
    end

    def qa_standard(id)
      repo.find_qa_standard(id)
    end

    def validate_qa_standard_params(params)
      QaStandardSchema.call(params)
    end
  end
end
