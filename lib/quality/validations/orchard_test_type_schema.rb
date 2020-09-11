# frozen_string_literal: true

module QualityApp
  OrchardTestTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:test_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:applies_to_all_markets).maybe(:bool)
    required(:applies_to_all_cultivars).maybe(:bool)
    optional(:applies_to_orchard).maybe(:bool)
    optional(:allow_result_capturing).maybe(:bool)
    optional(:pallet_level_result).maybe(:bool)
    optional(:api_name).maybe(Types::StrippedString)
    required(:result_type).filled(:string)
    optional(:api_attribute).maybe(:string)
    optional(:api_pass_result).maybe(Types::StrippedString)
    optional(:api_default_result).maybe(Types::StrippedString)
    optional(:applicable_tm_group_ids).maybe(:array).maybe { each(:integer) }
    optional(:applicable_cultivar_ids).maybe(:array).maybe { each(:integer) }
    optional(:applicable_commodity_group_ids).maybe(:array).maybe { each(:integer) }
  end
end
