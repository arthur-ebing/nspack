# frozen_string_literal: true

module FinishedGoodsApp
  GovtInspectionApiResultSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:govt_inspection_sheet_id).maybe(:integer)
    required(:govt_inspection_request_doc).maybe(:hash)
    required(:govt_inspection_result_doc).maybe(:hash)
    required(:results_requested).maybe(:bool)
    required(:results_requested_at).maybe(:time)
    required(:results_received).maybe(:bool)
    required(:results_received_at).maybe(:time)
    required(:upn_number).maybe(Types::StrippedString)
  end
end
