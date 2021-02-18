# frozen_string_literal: true

module FinishedGoodsApp
  class PassGovtInspectionPallet < BaseService
    attr_reader :ids, :repo

    def initialize(ids)
      @ids = Array(ids).flatten
      @repo = GovtInspectionRepo.new
    end

    def call
      ids.each do |id|
        pass_govt_inspection_pallet(id)
      end

      success_response('Govt inspection: Passed pallet.')
    end

    private

    def pass_govt_inspection_pallet(id)
      govt_inspection_sheet_id = repo.get(:govt_inspection_pallets, id, :govt_inspection_sheet_id)
      reinspection = repo.get(:govt_inspection_sheets, govt_inspection_sheet_id, :reinspection)
      attrs = { passed: true, inspected: true, failure_reason_id: nil, failure_remarks: nil }
      if reinspection
        attrs[:reinspected] = true
        attrs[:reinspected_at] = Time.now
      else
        attrs[:inspected_at] = Time.now
      end
      repo.update_govt_inspection_pallet(id, attrs)
    end
  end
end
