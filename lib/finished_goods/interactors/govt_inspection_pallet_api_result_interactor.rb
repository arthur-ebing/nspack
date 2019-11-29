# frozen_string_literal: true

module FinishedGoodsApp
  class GovtInspectionPalletApiResultInteractor < BaseInteractor
    def create_govt_inspection_pallet_api_result(params) # rubocop:disable Metrics/AbcSize
      res = validate_govt_inspection_pallet_api_result_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_govt_inspection_pallet_api_result(res)
        log_status(:govt_inspection_pallet_api_results, id, 'CREATED')
        log_transaction
      end
      instance = govt_inspection_pallet_api_result(id)
      success_response("Created govt inspection pallet api result #{instance.id}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This govt inspection pallet api result already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_govt_inspection_pallet_api_result(id, params)
      res = validate_govt_inspection_pallet_api_result_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_govt_inspection_pallet_api_result(id, res)
        log_transaction
      end
      instance = govt_inspection_pallet_api_result(id)
      success_response("Updated govt inspection pallet api result #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_govt_inspection_pallet_api_result(id)
      name = govt_inspection_pallet_api_result(id).id
      repo.transaction do
        repo.delete_govt_inspection_pallet_api_result(id)
        log_status(:govt_inspection_pallet_api_results, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted govt inspection pallet api result #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::GovtInspectionPalletApiResult.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GovtInspectionPalletApiResultRepo.new
    end

    def govt_inspection_pallet_api_result(id)
      repo.find_govt_inspection_pallet_api_result(id)
    end

    def validate_govt_inspection_pallet_api_result_params(params)
      GovtInspectionPalletApiResultSchema.call(params)
    end
  end
end
