# frozen_string_literal: true

module ProductionApp
  class SystemResource < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_type_id, Types::Integer
    attribute :system_resource_type_id, Types::Integer
    attribute :system_resource_code, Types::String
    attribute :description, Types::String
    attribute :equipment_type, Types::String
    attribute :module_function, Types::String
    attribute :mac_address, Types::String
    attribute :ip_address, Types::String
    attribute :port, Types::Integer
    attribute :ttl, Types::Integer
    attribute :cycle_time, Types::Integer
    attribute :publishing, Types::Bool
    attribute :login, Types::Bool
    attribute :logoff, Types::Bool
    attribute :group_incentive, Types::Bool
    attribute :module_action, Types::String
    attribute :peripheral_model, Types::String
    attribute :connection_type, Types::String
    attribute :printer_language, Types::String
    attribute :print_username, Types::String
    attribute :print_password, Types::String
    attribute :pixels_mm, Types::Integer
    attribute :robot_function, Types::String
    attribute? :active, Types::Bool
  end

  class SystemResourceFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :plant_resource_type_id, Types::Integer
    attribute :plant_resource_type_code, Types::String
    attribute :system_resource_type_id, Types::Integer
    attribute :system_resource_type_code, Types::String
    attribute :system_resource_code, Types::String
    attribute :plant_resource_code, Types::String
    attribute :plant_resource_id, Types::Integer
    attribute :description, Types::String
    attribute :equipment_type, Types::String
    attribute :module_function, Types::String
    attribute :mac_address, Types::String
    attribute :ip_address, Types::String
    attribute :port, Types::Integer
    attribute :ttl, Types::Integer
    attribute :cycle_time, Types::Integer
    attribute :publishing, Types::Bool
    attribute :login, Types::Bool
    attribute :logoff, Types::Bool
    attribute :group_incentive, Types::Bool
    attribute :module_action, Types::String
    attribute :peripheral_model, Types::String
    attribute :connection_type, Types::String
    attribute :printer_language, Types::String
    attribute :print_username, Types::String
    attribute :print_password, Types::String
    attribute :pixels_mm, Types::Integer
    attribute :robot_function, Types::String
    attribute? :active, Types::Bool
  end
end
