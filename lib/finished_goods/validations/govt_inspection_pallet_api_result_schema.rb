# frozen_string_literal: true

module FinishedGoodsApp
  GovtInspectionPalletApiResultSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:passed, :bool).maybe(:bool?)
    required(:failure_reasons, :hash).maybe(:hash?)
    required(:govt_inspection_pallet_id, :integer).maybe(:int?)
    required(:govt_inspection_api_result_id, :integer).maybe(:int?)
  end
end
