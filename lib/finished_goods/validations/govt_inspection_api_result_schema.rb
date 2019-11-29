# frozen_string_literal: true

module FinishedGoodsApp
  GovtInspectionApiResultSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:govt_inspection_sheet_id, :integer).maybe(:int?)
    required(:govt_inspection_request_doc, :hash).maybe(:hash?)
    required(:govt_inspection_result_doc, :hash).maybe(:hash?)
    required(:results_requested, :bool).maybe(:bool?)
    required(:results_requested_at, %i[nil time]).maybe(:time?)
    required(:results_received, :bool).maybe(:bool?)
    required(:results_received_at, %i[nil time]).maybe(:time?)
    required(:upn_number, Types::StrippedString).maybe(:str?)
  end
end
