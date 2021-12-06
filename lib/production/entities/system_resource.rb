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
    attribute :legacy_messcada, Types::Bool
    attribute :module_action, Types::String
    attribute :peripheral_model, Types::String
    attribute :connection_type, Types::String
    attribute :printer_language, Types::String
    attribute :print_username, Types::String
    attribute :print_password, Types::String
    attribute :pixels_mm, Types::Integer
    attribute :robot_function, Types::String
    attribute? :extended_config, Types::Hash
    attribute? :active, Types::Bool
  end

  class SystemResourceIncentiveSettings < Dry::Struct
    attribute :id, Types::Integer
    attribute :system_resource_code, Types::String
    attribute :login, Types::Bool
    attribute :logoff, Types::Bool
    attribute :group_incentive, Types::Bool
    attribute :packpoint, Types::String
    attribute :cache_key, Types::String
    attribute :card_reader, Types::String
  end

  class SystemResourceWithIncentive < Dry::Struct
    attribute :id, Types::Integer
    attribute :system_resource_code, Types::String
    attribute :login, Types::Bool
    attribute :logoff, Types::Bool
    attribute :group_incentive, Types::Bool
    attribute :packpoint, Types::String
    attribute :cache_key, Types::String
    attribute :card_reader, Types::String
    attribute? :contract_worker_id, Types::Integer
    attribute? :personnel_identifier_id, Types::Integer
    attribute? :group_incentive_id, Types::Integer
    attribute? :identifier, Types::String
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
    attribute :legacy_messcada, Types::Bool
    attribute :module_action, Types::String
    attribute :peripheral_model, Types::String
    attribute :connection_type, Types::String
    attribute :printer_language, Types::String
    attribute :print_username, Types::String
    attribute :print_password, Types::String
    attribute :pixels_mm, Types::Integer
    attribute :robot_function, Types::String
    attribute? :extended_config, Types::Hash
    attribute? :active, Types::Bool
  end
end
