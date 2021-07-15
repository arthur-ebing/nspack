# frozen_string_literal: true

module FinishedGoodsApp
  EcertTrackingUnitSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:pallet_id).filled(:integer)
    required(:ecert_agreement_id).filled(:integer)
    required(:business_id).filled(:integer)
    required(:industry).filled(Types::StrippedString)
    required(:elot_key).maybe(Types::StrippedString)
    required(:verification_key).maybe(Types::StrippedString)
    required(:passed).filled(:bool)
    required(:process_result).maybe(:array).maybe { each(:string) }
    required(:rejection_reasons).maybe(:array).maybe { each(:string) }
  end

  EcertElotSchema = Dry::Schema.Params do
    required(:ecert_agreement_id).filled(:integer)
    required(:pallet_list).filled(Types::StrippedString)
  end
end
