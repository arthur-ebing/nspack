# frozen_string_literal: true

module MasterfilesApp
  class ScrapReasonInteractor < BaseInteractor
    def create_scrap_reason(params)  # rubocop:disable Metrics/AbcSize
      res = validate_scrap_reason_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_scrap_reason(res)
        log_status('scrap_reasons', id, 'CREATED')
        log_transaction
      end
      instance = scrap_reason(id)
      success_response("Created scrap reason #{instance.scrap_reason}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { scrap_reason: ['This scrap reason already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_scrap_reason(id, params)
      res = validate_scrap_reason_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_scrap_reason(id, res)
        log_transaction
      end
      instance = scrap_reason(id)
      success_response("Updated scrap reason #{instance.scrap_reason}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_scrap_reason(id)
      name = scrap_reason(id).scrap_reason
      repo.transaction do
        repo.delete_scrap_reason(id)
        log_status('scrap_reasons', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted scrap reason #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ScrapReason.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QualityRepo.new
    end

    def scrap_reason(id)
      repo.find_scrap_reason(id)
    end

    def validate_scrap_reason_params(params)
      ScrapReasonSchema.call(params)
    end
  end
end
