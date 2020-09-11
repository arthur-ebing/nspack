# frozen_string_literal: true

module MasterfilesApp
  class MarkInteractor < BaseInteractor
    def create_mark(params) # rubocop:disable Metrics/AbcSize
      res = validate_mark_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_mark(res)
        log_status('marks', id, 'CREATED')
        log_transaction
      end
      instance = mark(id)
      success_response("Created mark #{instance.mark_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { mark_code: ['This mark already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_mark(id, params)
      res = validate_mark_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_mark(id, res)
        log_transaction
      end
      instance = mark(id)
      success_response("Updated mark #{instance.mark_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_mark(id)
      name = mark(id).mark_code
      repo.transaction do
        repo.delete_mark(id)
        log_status('marks', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted mark #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::Mark.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= MarketingRepo.new
    end

    def mark(id)
      repo.find_mark(id)
    end

    def validate_mark_params(params)
      MarkSchema.call(params)
    end
  end
end
