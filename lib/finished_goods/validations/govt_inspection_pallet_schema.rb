# frozen_string_literal: true

module FinishedGoodsApp
  GovtInspectionPalletSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:pallet_id, :integer).filled(:int?)
    required(:govt_inspection_sheet_id, :integer).filled(:int?)
    optional(:passed, :bool).maybe(:bool?)
    optional(:inspected, :bool).maybe(:bool?)
    optional(:inspected_at, %i[nil time]).maybe(:time?)
    optional(:failure_reason_id, :integer).maybe(:int?)
    optional(:failure_remarks, Types::StrippedString).maybe(:str?)
  end

  GovtInspectionAddPalletSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:pallet_number, :string).filled(:str?)
    required(:govt_inspection_sheet_id, :integer).filled(:int?)
  end

  GovtInspectionFailedPalletSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:failure_reason_id, :integer).filled(:int?)
    required(:failure_remarks, Types::StrippedString).maybe(:str?)
  end
end
