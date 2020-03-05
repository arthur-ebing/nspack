# frozen_string_literal: true

module QualityApp
  class OrchardTestType < Dry::Struct
    attribute :id, Types::Integer
    attribute :test_type_code, Types::String
    attribute :description, Types::String
    attribute :applies_to_all_markets, Types::Bool
    attribute :applies_to_all_cultivars, Types::Bool
    attribute :applies_to_orchard, Types::Bool
    attribute :allow_result_capturing, Types::Bool
    attribute :pallet_level_result, Types::Bool
    attribute :api_name, Types::String
    attribute :result_type, Types::String
    attribute :result_attribute, Types::String
    attribute :applicable_tm_group_ids, Types::Array
    attribute :applicable_cultivar_ids, Types::Array
    attribute :applicable_commodity_group_ids, Types::Array
    attribute? :active, Types::Bool
  end

  class OrchardTestTypeFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :test_type_code, Types::String
    attribute :description, Types::String
    attribute :applies_to_all_markets, Types::Bool
    attribute :applies_to_all_cultivars, Types::Bool
    attribute :applies_to_orchard, Types::Bool
    attribute :allow_result_capturing, Types::Bool
    attribute :pallet_level_result, Types::Bool
    attribute :api_name, Types::String
    attribute :result_type, Types::String
    attribute :result_attribute, Types::String
    attribute :applicable_tm_group_ids, Types::Array
    attribute :applicable_tm_groups, Types::String
    attribute :applicable_cultivar_ids, Types::Array
    attribute :applicable_cultivars, Types::String
    attribute :applicable_commodity_group_ids, Types::Array
    attribute :applicable_commodity_groups, Types::String
    attribute? :active, Types::Bool
  end
end
