# frozen_string_literal: true

module ProductionApp
  SystemResourceModuleSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:equipment_type, Types::StrippedString).maybe(:str?)
    required(:module_function, Types::StrippedString).maybe(:str?)
    required(:mac_address, Types::StrippedString).maybe(:str?)
    required(:ip_address, Types::StrippedString).maybe(:str?)
    required(:port, :integer).maybe(:int?)
    required(:ttl, :integer).maybe(:int?)
    required(:cycle_time, :integer).maybe(:int?)
    required(:publishing, :bool).maybe(:bool?)
    required(:login, :bool).maybe(:bool?)
    required(:logoff, :bool).maybe(:bool?)
    required(:module_action, Types::StrippedString).maybe(:str?)
    required(:robot_function, Types::StrippedString).maybe(:str?)
  end

  SystemResourcePeripheralSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:equipment_type, Types::StrippedString).maybe(:str?)
    required(:module_function, Types::StrippedString).maybe(:str?)
    required(:ip_address, Types::StrippedString).maybe(:str?)
    required(:port, :integer).maybe(:int?)
    required(:ttl, :integer).maybe(:int?)
    required(:cycle_time, :integer).maybe(:int?)
    required(:peripheral_model, Types::StrippedString).maybe(:str?)
    required(:connection_type, Types::StrippedString).maybe(:str?)
    required(:printer_language, Types::StrippedString).maybe(:str?)
    required(:print_username, Types::StrippedString).maybe(:str?)
    required(:print_password, Types::StrippedString).maybe(:str?)
    required(:pixels_mm, :integer).maybe(:int?)
  end
end
