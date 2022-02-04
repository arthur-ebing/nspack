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

  SystemResourceNetworkSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:mac_address).maybe(Types::StrippedString)
    required(:ip_address).maybe(Types::StrippedString)
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
    optional(:ip_address).maybe(Types::StrippedString)
    optional(:port).maybe(:integer)
    optional(:ttl).maybe(:integer)
    optional(:cycle_time).maybe(:integer)
    required(:peripheral_model).maybe(Types::StrippedString)
    required(:connection_type).maybe(Types::StrippedString)
    optional(:print_username).maybe(Types::StrippedString)
    optional(:print_password).maybe(Types::StrippedString)
    optional(:pixels_mm).maybe(:integer)
    optional(:extended_config).hash do
      optional(:distro_type).maybe(Types::StrippedString)
      optional(:buffer_size).maybe(:integer)
      optional(:start_of_input).maybe(Types::StrippedString)
      optional(:end_of_input).maybe(Types::StrippedString)
      optional(:strip_start_of_input).maybe(:bool)
      optional(:strip_end_of_input).maybe(:bool)
      optional(:baud_rate).maybe(:integer)
      optional(:parity).maybe(Types::StrippedString)
      optional(:flow_control).maybe(Types::StrippedString)
      optional(:data_bits).maybe(:integer)
      optional(:stop_bits).maybe(:integer)
    end
  end

  SystemResourceButtonSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:extended_config).hash do
      required(:no_of_labels_to_print).maybe(:integer)
    end
  end

  SystemResourceModuleConfigSchema = Dry::Schema.Params do
    required(:equipment_type).filled(Types::StrippedString)
    required(:module_function).filled(Types::StrippedString)
    required(:mac_address).maybe(Types::StrippedString)
    required(:ip_address).filled(Types::StrippedString)
    required(:port).filled(:integer)
    required(:ttl).filled(:integer)
    required(:cycle_time).filled(:integer)
    required(:publishing).filled(:bool)
    required(:module_action).filled(Types::StrippedString)
    required(:robot_function).filled(Types::StrippedString)
    required(:extended_config).hash do
      required(:distro_type).filled(Types::StrippedString)
    end
  end

  class SystemResourcePrinterConfigSchema < Dry::Validation::Contract
    option :printer_set

    params do
      required(:equipment_type).filled(Types::StrippedString)
      required(:module_function).filled(Types::StrippedString)
      required(:ip_address).maybe(Types::StrippedString)
      required(:port).maybe(:integer)
      required(:ttl).maybe(:integer)
      required(:cycle_time).maybe(:integer)
      required(:peripheral_model).filled(Types::StrippedString)
      required(:connection_type).filled(Types::StrippedString, included_in?: %w[TCP USB])
      required(:pixels_mm).filled(:integer, included_in?: [8, 12])
    end

    rule(:connection_type) do
      key.failure 'is TCP, so ip address, port, TTL and cycle time must be present for printer.' if value == 'TCP' && %i[ip_address port ttl cycle_time].any? { |k| values[k].nil? }
    end

    rule(:equipment_type) do
      key.failure 'is invalid for printer.' unless printer_set[value]
    end

    rule(:peripheral_model) do
      key.failure 'is invalid for printer.' unless printer_set[values[:equipment_type]][values[:peripheral_model]]
    end
  end

  class SystemResourceScaleConfigSchema < Dry::Validation::Contract
    params do
      required(:equipment_type).filled(Types::StrippedString)
      required(:ip_address).maybe(Types::StrippedString)
      required(:port).maybe(:integer)
      required(:ttl).maybe(:integer)
      required(:cycle_time).maybe(:integer)
      required(:peripheral_model).filled(Types::StrippedString)
      required(:connection_type).filled(Types::StrippedString, included_in?: %w[TCP RS232])
      required(:extended_config).hash do
        required(:buffer_size).filled(:integer)
        required(:start_of_input).maybe(Types::StrippedString)
        required(:end_of_input).maybe(Types::StrippedString)
        required(:strip_start_of_input).filled(:bool)
        required(:strip_end_of_input).filled(:bool)
        required(:baud_rate).filled(:integer)
        required(:parity).filled(Types::StrippedString)
        required(:flow_control).filled(Types::StrippedString)
        required(:data_bits).filled(:integer)
        required(:stop_bits).filled(:integer)
      end
    end

    rule(:connection_type) do
      key.failure 'is TCP, so ip address, port, TTL and cycle time must be present for scale.' if value == 'TCP' && %i[ip_address port ttl cycle_time].any? { |k| values[k].nil? }
    end
  end

  class SystemResourceScannerConfigSchema < Dry::Validation::Contract
    params do
      required(:equipment_type).filled(Types::StrippedString)
      required(:ip_address).maybe(Types::StrippedString)
      required(:port).maybe(:integer)
      required(:ttl).maybe(:integer)
      required(:cycle_time).maybe(:integer)
      required(:peripheral_model).filled(Types::StrippedString)
      required(:connection_type).filled(Types::StrippedString, included_in?: %w[TCP USB SERIAL WEDGE])
      required(:extended_config).hash do
        required(:buffer_size).filled(:integer)
        required(:start_of_input).maybe(Types::StrippedString)
        required(:end_of_input).maybe(Types::StrippedString)
        required(:strip_start_of_input).filled(:bool)
        required(:strip_end_of_input).filled(:bool)
      end
    end

    rule(:connection_type) do
      key.failure 'is TCP, so ip address, port, TTL and cycle time must be present for scanner.' if value == 'TCP' && %i[ip_address port ttl cycle_time].any? { |k| values[k].nil? }
    end
  end
end
