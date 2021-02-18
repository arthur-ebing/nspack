# frozen_string_literal: true

module FinishedGoodsApp
  class FailGovtInspectionPallet < BaseService
    attr_reader :id, :repo
    attr_accessor :params

    def initialize(id, params)
      @id = id
      @params = params.to_h
      @repo = GovtInspectionRepo.new
    end

    def call
      res = FailGovtInspectionPalletSchema.call(params)
      return validation_failed_response(res) if res.failure?

      fail_govt_inspection_pallet(id)

      success_response('Govt inspection: Failed pallet.')
    end

    private

    def fail_govt_inspection_pallet(id) # rubocop:disable Metrics/AbcSize
      govt_inspection_sheet_id = repo.get(:govt_inspection_pallets, id, :govt_inspection_sheet_id)
      reinspection = repo.get(:govt_inspection_sheets, govt_inspection_sheet_id, :reinspection)
      params[:passed] = false
      params[:inspected] = true
      if reinspection
        params[:reinspected] = true
        params[:reinspected_at] = Time.now
      else
        params[:inspected_at] = Time.now
      end
      repo.update_govt_inspection_pallet(id, params)
    end
  end
end
