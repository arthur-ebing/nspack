# frozen_string_literal: true

module ProductionApp
  class Robot < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_code, Types::String
    attribute :description, Types::String
    attribute :system_resource_code, Types::String
    attribute :system_resource_description, Types::String
    attribute :active, Types::Bool
    attribute :equipment_type, Types::String
    attribute :module_function, Types::String
    attribute :mac_address, Types::String
    attribute :module_action, Types::String
    attribute :robot_function, Types::String
  end
end
