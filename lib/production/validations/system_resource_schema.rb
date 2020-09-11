# frozen_string_literal: true

module ProductionApp
  SystemResourceModuleSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:equipment_type).maybe(Types::StrippedString)
    required(:module_function).maybe(Types::StrippedString)
    required(:mac_address).maybe(Types::StrippedString)
    required(:ip_address).maybe(Types::StrippedString)
    required(:port).maybe(:integer)
    required(:ttl).maybe(:integer)
    required(:cycle_time).maybe(:integer)
    required(:publishing).maybe(:bool)
    required(:login).maybe(:bool)
    required(:logoff).maybe(:bool)
    required(:module_action).maybe(Types::StrippedString)
    required(:robot_function).maybe(Types::StrippedString)
  end

  SystemResourcePeripheralSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:equipment_type).maybe(Types::StrippedString)
    required(:module_function).maybe(Types::StrippedString)
    required(:ip_address).maybe(Types::StrippedString)
    required(:port).maybe(:integer)
    required(:ttl).maybe(:integer)
    required(:cycle_time).maybe(:integer)
    required(:peripheral_model).maybe(Types::StrippedString)
    required(:connection_type).maybe(Types::StrippedString)
    required(:printer_language).maybe(Types::StrippedString)
    required(:print_username).maybe(Types::StrippedString)
    required(:print_password).maybe(Types::StrippedString)
    required(:pixels_mm).maybe(:integer)
  end
end
