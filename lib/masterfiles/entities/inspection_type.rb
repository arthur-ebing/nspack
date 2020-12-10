# frozen_string_literal: true

module MasterfilesApp
  class InspectionType < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspection_type_code, Types::String
    attribute :description, Types::String
    attribute :inspection_failure_type_id, Types::Integer
    attribute :applies_to_all_tm_groups, Types::Bool
    attribute :applicable_tm_group_ids, Types::Array
    attribute :applies_to_all_cultivars, Types::Bool
    attribute :applicable_cultivar_ids, Types::Array
    attribute :applies_to_all_orchards, Types::Bool
    attribute :applicable_orchard_ids, Types::Array
    attribute? :active, Types::Bool
  end

  class InspectionTypeFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :inspection_type_code, Types::String
    attribute :description, Types::String
    attribute :inspection_failure_type_id, Types::Integer
    attribute :failure_type_code, Types::String
    attribute :applicable_tm_group_ids, Types::Array
    attribute :applicable_tm_groups, Types::Array
    attribute :applicable_cultivar_ids, Types::Array
    attribute :applicable_cultivars, Types::Array
    attribute :applicable_orchard_ids, Types::Array
    attribute :applicable_orchards, Types::Array
    attribute? :active, Types::Bool
  end
end
