# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionApiResultInteractor < BaseInteractor
    def create_govt_inspection_api_result(params) # rubocop:disable Metrics/AbcSize
      res = validate_govt_inspection_api_result_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_govt_inspection_api_result(res)
        log_status(:govt_inspection_api_results, id, 'CREATED')
        log_transaction
      end
      instance = govt_inspection_api_result(id)
      success_response("Created govt inspection api result #{instance.upn_number}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { upn_number: ['This govt inspection api result already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_api_result(id, params)
      res = validate_govt_inspection_api_result_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_govt_inspection_api_result(id, res)
        log_transaction
      end
      instance = govt_inspection_api_result(id)
      success_response("Updated govt inspection api result #{instance.upn_number}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_api_result(id)
      name = govt_inspection_api_result(id).upn_number
      repo.transaction do
        repo.delete_govt_inspection_api_result(id)
        log_status(:govt_inspection_api_results, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted govt inspection api result #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionApiResult.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GovtInspectionRepo.new
    end

    def govt_inspection_api_result(id)
      repo.find_govt_inspection_api_result(id)
    end

    def validate_govt_inspection_api_result_params(params)
      GovtInspectionApiResultSchema.call(params)
    end
  end
end
