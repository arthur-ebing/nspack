# frozen_string_literal: true

module FinishedGoodsApp
  GovtInspectionPalletApiResultSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:passed).maybe(:bool)
    required(:failure_reasons).maybe(:hash)
    required(:govt_inspection_pallet_id).maybe(:integer)
    required(:govt_inspection_api_result_id).maybe(:integer)
  end
end
