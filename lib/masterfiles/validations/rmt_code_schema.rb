# frozen_string_literal: true

module MasterfilesApp
  RmtCodeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:rmt_variant_id).filled(:integer)
    required(:rmt_handling_regime_id).filled(:integer)
    required(:rmt_code).filled(Types::StrippedString)
    optional(:legacy_code).maybe(Types::StrippedString)
    optional(:description).maybe(Types::StrippedString)
  end
end
