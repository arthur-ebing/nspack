# frozen_string_literal: true

module FinishedGoodsApp
  CreateGovtInspectionPalletSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:govt_inspection_sheet_id).filled(:integer)
    required(:pallet_id).filled(:integer)
    optional(:carton_id).maybe(:integer)
    optional(:passed).maybe(:bool)
    optional(:inspected).maybe(:bool)
    optional(:inspected_at).maybe(:time)
    optional(:failure_reason_id).maybe(:integer)
    optional(:failure_remarks).maybe(Types::StrippedString)
  end

  UpdateGovtInspectionPalletSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:passed).maybe(:bool)
    optional(:inspected).maybe(:bool)
    optional(:inspected_at).maybe(:time)
    optional(:failure_reason_id).maybe(:integer)
    optional(:failure_remarks).maybe(Types::StrippedString)
  end

  FailGovtInspectionPalletSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:failure_reason_id).filled(:integer)
    required(:failure_remarks).maybe(Types::StrippedString)
  end
end
