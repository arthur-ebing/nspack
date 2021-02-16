# frozen_string_literal: true

module FinishedGoodsApp
  class InspectionContract < Dry::Validation::Contract
    params do
      optional(:id).filled(:integer)
      required(:inspector_id).filled(:integer)
      optional(:inspection_failure_reason_ids).maybe(:array).maybe { each(:integer) }
      required(:passed).maybe(:bool)
      required(:remarks).maybe(Types::StrippedString)
    end

    rule(:inspection_failure_reason_ids) do
      key.failure('must provide a failure reason') if !values[:passed] && values[:inspection_failure_reason_ids].nil_or_empty?
    end

    rule(:remarks) do
      key.failure('must provide a comment') if !values[:passed] && values[:remarks].nil_or_empty?
    end
  end

  InspectionPalletSchema = Dry::Schema.Params do
    required(:pallet_number).filled(Types::StrippedString)
  end
end
