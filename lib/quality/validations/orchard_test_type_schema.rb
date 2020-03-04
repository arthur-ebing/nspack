# frozen_string_literal: true

module QualityApp
  OrchardTestTypeSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:test_type_code, Types::StrippedString).filled(:str?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:applies_to_all_markets, :bool).maybe(:bool?)
    required(:applies_to_all_cultivars, :bool).maybe(:bool?)
    required(:applies_to_orchard, :bool).maybe(:bool?)
    required(:applies_to_orchard_set, :bool).maybe(:bool?)
    required(:allow_result_capturing, :bool).maybe(:bool?)
    required(:pallet_level_result, :bool).maybe(:bool?)
    optional(:api_name, Types::StrippedString).maybe(:str?)
    required(:result_type, :string).filled(:str?)
    optional(:result_attribute, :string).maybe(:str?)
    optional(:applicable_tm_group_ids, Types::IntArray).maybe { each(:int?) }
    optional(:applicable_cultivar_ids, Types::IntArray).maybe { each(:int?) }
    optional(:applicable_commodity_group_ids, Types::IntArray).maybe { each(:int?) }
  end
end
