# frozen_string_literal: true

module ProductionApp
  SystemResourceServerSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:equipment_type).maybe(Types::StrippedString)
    required(:module_function).maybe(Types::StrippedString)
    required(:mac_address).maybe(Types::StrippedString)
    required(:ip_address).maybe(Types::StrippedString)
    required(:port).maybe(:integer)
    required(:ttl).maybe(:integer)
    required(:cycle_time).maybe(:integer)
    required(:publishing).maybe(:bool)
    required(:module_action).maybe(Types::StrippedString)
    required(:robot_function).maybe(Types::StrippedString)
    optional(:extended_config).hash do
      optional(:netmask).maybe(Types::StrippedString)
      optional(:gateway).maybe(Types::StrippedString)
    end
  end

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
    required(:group_incentive).maybe(:bool)
    required(:legacy_messcada).maybe(:bool)
    required(:module_action).maybe(Types::StrippedString)
    required(:robot_function).maybe(Types::StrippedString)
    optional(:extended_config).hash do
      optional(:distro_type).maybe(Types::StrippedString)
    end
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

  SystemResourceButtonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:extended_config).hash do
      required(:no_of_labels_to_print).maybe(:integer)
    end
  end
end
