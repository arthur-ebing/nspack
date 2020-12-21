# frozen_string_literal: true

module ProductionApp
  class PlantResourceType < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_type_code, Types::String
    attribute :description, Types::String
    # attribute :attribute_rules, Types::Hash
    # attribute :behaviour_rules, Types::Hash
    attribute? :active, Types::Bool
    attribute? :packpoint, Types::Bool
    attribute? :icon, Types::String
  end
end
