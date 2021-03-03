# frozen_string_literal: true

module ProductionApp
  class PlantResource < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_type_id, Types::Integer
    attribute :system_resource_id, Types::Integer
    attribute :plant_resource_code, Types::String
    attribute :description, Types::String
    attribute :represents_plant_resource_id, Types::Integer
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
    attribute :represents_plant_resource_id, Types::Integer
    attribute :represents_plant_resource_code, Types::String
    attribute :system_resource_code, Types::String
    attribute :location_id, Types::Integer
    attribute :location_long_code, Types::String
    attribute? :resource_properties, Types::Hash
    attribute? :active, Types::Bool
  end

  class PlantResourceFlatForGrid < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_type_id, Types::Integer
    attribute :plant_resource_type_code, Types::String
    attribute :packpoint, Types::Bool
    attribute :system_resource_id, Types::Integer
    attribute :plant_resource_code, Types::String
    attribute :description, Types::String
    attribute :system_resource_code, Types::String
    attribute :active, Types::Bool
    attribute :icon, Types::String
    attribute :phc, Types::String
    attribute :ph_no, Types::String
    attribute :gln, Types::String
    attribute :linked_resources, Types::String
    attribute :type_description, Types::String
    attribute :path_array, Types::Array
    attribute :level, Types::Integer
    attribute :peripheral, Types::Bool
  end
end
