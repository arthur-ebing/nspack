# frozen_string_literal: true

module MasterfilesApp
  class InnerPmMarkInteractor < BaseInteractor
    def create_inner_pm_mark(params) # rubocop:disable Metrics/AbcSize
      res = validate_inner_pm_mark_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_inner_pm_mark(res)
        log_status(:inner_pm_marks, id, 'CREATED')
        log_transaction
      end
      instance = inner_pm_mark(id)
      success_response("Created Inner PKG Mark #{instance.description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { inner_pm_mark_code: ['This Inner PKG Mark already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_inner_pm_mark(id, params)
      res = validate_inner_pm_mark_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_inner_pm_mark(id, res)
        log_transaction
      end
      instance = inner_pm_mark(id)
      success_response("Updated Inner PKG Mark #{instance.description}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_inner_pm_mark(id) # rubocop:disable Metrics/AbcSize
      name = inner_pm_mark(id).description
      repo.transaction do
        repo.delete_inner_pm_mark(id)
        log_status(:inner_pm_marks, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted Inner PKG Mark #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete Inner PKG Mark. It is still referenced#{e.message.partition('referenced').last}")
    end

    # def complete_a_inner_pm_mark(id, params)
    #   res = complete_a_record(:inner_pm_marks, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, inner_pm_mark(id))
    #   else
    #     failed_response(res.message, inner_pm_mark(id))
    #   end
    # end

    # def reopen_a_inner_pm_mark(id, params)
    #   res = reopen_a_record(:inner_pm_marks, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, inner_pm_mark(id))
    #   else
    #     failed_response(res.message, inner_pm_mark(id))
    #   end
    # end

    # def approve_or_reject_a_inner_pm_mark(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:inner_pm_marks, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:inner_pm_marks, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, inner_pm_mark(id))
    #   else
    #     failed_response(res.message, inner_pm_mark(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::InnerPmMark.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= InnerPmMarkRepo.new
    end

    def inner_pm_mark(id)
      repo.find_inner_pm_mark(id)
    end

    def validate_inner_pm_mark_params(params)
      InnerPmMarkSchema.call(params)
    end
  end
end
