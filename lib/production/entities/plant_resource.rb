# frozen_string_literal: true

module ProductionApp
  class PlantResource < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_type_id, Types::Integer
    attribute :system_resource_id, Types::Integer
    attribute :plant_resource_code, Types::String
    attribute :description, Types::String
    attribute :location_id, Types::Integer
    attribute? :resource_properties, Types::Hash
    attribute? :active, Types::Bool
  end

  class PlantResourceFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_type_id, Types::Integer
    attribute :plant_resource_type_code, Types::String
    attribute :packpoint, Types::Bool
    attribute :system_resource_id, Types::Integer
    attribute :plant_resource_code, Types::String
    attribute :description, Types::String
    attribute :system_resource_code, Types::String
    attribute :location_id, Types::Integer
    attribute :location_long_code, Types::String
    attribute? :resource_properties, Types::Hash
    attribute? :active, Types::Bool
  end
end
