# frozen_string_literal: true

module FinishedGoodsApp
  EcertTrackingUnitSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:pallet_id, :integer).filled(:int?)
    required(:ecert_agreement_id, :integer).filled(:int?)
    required(:business_id, :integer).filled(:int?)
    required(:industry, Types::StrippedString).filled(:str?)
    required(:elot_key, Types::StrippedString).maybe(:str?)
    required(:verification_key, Types::StrippedString).maybe(:str?)
    required(:passed, :bool).filled(:bool?)
    required(:process_result, :array).maybe(:array?) { each(:str?) }
    required(:rejection_reasons, :array).maybe(:array?) { each(:str?) }
  end

  EcertElotSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    required(:ecert_agreement_id, :integer).filled(:int?)
    required(:pallet_list, Types::StrippedString).filled(:str?)
  end
end
