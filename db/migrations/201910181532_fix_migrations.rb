require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    # Drop logging for load_vehicles table.
    drop_trigger(:load_vehicles, :audit_trigger_row)
    drop_trigger(:load_vehicles, :audit_trigger_stm)

    drop_trigger(:load_vehicles, :set_created_at)
    drop_function(:load_vehicles_set_created_at)
    drop_trigger(:load_vehicles, :set_updated_at)
    drop_function(:load_vehicles_set_updated_at)
    drop_table(:load_vehicles)

    # Drop logging for load_voyages table.
    drop_trigger(:load_voyages, :audit_trigger_row)
    drop_trigger(:load_voyages, :audit_trigger_stm)

    drop_trigger(:load_voyages, :set_created_at)
    drop_function(:load_voyages_set_created_at)
    drop_trigger(:load_voyages, :set_updated_at)
    drop_function(:load_voyages_set_updated_at)
    drop_table(:load_voyages)

    # Drop logging for load_containers table.
    drop_trigger(:load_containers, :audit_trigger_row)
    drop_trigger(:load_containers, :audit_trigger_stm)

    drop_trigger(:load_containers, :set_created_at)
    drop_function(:load_containers_set_created_at)
    drop_trigger(:load_containers, :set_updated_at)
    drop_function(:load_containers_set_updated_at)
    drop_table(:load_containers)

    # Drop logging for loads table.
    drop_trigger(:loads, :audit_trigger_row)
    drop_trigger(:loads, :audit_trigger_stm)

    drop_trigger(:loads, :set_created_at)
    drop_function(:loads_set_created_at)
    drop_trigger(:loads, :set_updated_at)
    drop_function(:loads_set_updated_at)
    drop_table(:loads)

    # Drop logging for voyage_ports table.
    drop_trigger(:voyage_ports, :audit_trigger_row)
    drop_trigger(:voyage_ports, :audit_trigger_stm)

    drop_trigger(:voyage_ports, :set_created_at)
    drop_function(:voyage_ports_set_created_at)
    drop_trigger(:voyage_ports, :set_updated_at)
    drop_function(:voyage_ports_set_updated_at)
    drop_table(:voyage_ports)

    # Drop logging for voyages table.
    drop_trigger(:voyages, :audit_trigger_row)
    drop_trigger(:voyages, :audit_trigger_stm)

    drop_trigger(:voyages, :set_created_at)
    drop_function(:voyages_set_created_at)
    drop_trigger(:voyages, :set_updated_at)
    drop_function(:voyages_set_updated_at)
    drop_table(:voyages)

    # Drop logging for vessels table.
    drop_trigger(:vessels, :audit_trigger_row)
    drop_trigger(:vessels, :audit_trigger_stm)

    drop_trigger(:vessels, :set_created_at)
    drop_function(:vessels_set_created_at)
    drop_trigger(:vessels, :set_updated_at)
    drop_function(:vessels_set_updated_at)
    drop_table(:vessels)

    # Drop logging for ports table.
    drop_trigger(:ports, :audit_trigger_row)
    drop_trigger(:ports, :audit_trigger_stm)

    drop_trigger(:ports, :set_created_at)
    drop_function(:ports_set_created_at)
    drop_trigger(:ports, :set_updated_at)
    drop_function(:ports_set_updated_at)
    drop_table(:ports)

    # Drop logging for vessel_types table.
    drop_trigger(:vessel_types, :audit_trigger_row)
    drop_trigger(:vessel_types, :audit_trigger_stm)

    drop_trigger(:vessel_types, :set_created_at)
    drop_function(:vessel_types_set_created_at)
    drop_trigger(:vessel_types, :set_updated_at)
    drop_function(:vessel_types_set_updated_at)
    drop_table(:vessel_types)

    # Drop logging for port_types table.
    drop_trigger(:port_types, :audit_trigger_row)
    drop_trigger(:port_types, :audit_trigger_stm)

    drop_trigger(:port_types, :set_created_at)
    drop_function(:port_types_set_created_at)
    drop_trigger(:port_types, :set_updated_at)
    drop_function(:port_types_set_updated_at)
    drop_table(:port_types)

    # Drop logging for voyage_types table.
    drop_trigger(:voyage_types, :audit_trigger_row)
    drop_trigger(:voyage_types, :audit_trigger_stm)

    drop_trigger(:voyage_types, :set_created_at)
    drop_function(:voyage_types_set_created_at)
    drop_trigger(:voyage_types, :set_updated_at)
    drop_function(:voyage_types_set_updated_at)
    drop_table(:voyage_types)

    # Drop logging for vehicle_types table.
    drop_trigger(:vehicle_types, :audit_trigger_row)
    drop_trigger(:vehicle_types, :audit_trigger_stm)

    drop_trigger(:vehicle_types, :set_created_at)
    drop_function(:vehicle_types_set_created_at)
    drop_trigger(:vehicle_types, :set_updated_at)
    drop_function(:vehicle_types_set_updated_at)
    drop_table(:vehicle_types)

    # Drop logging for destination_depots table.
    drop_trigger(:depots, :audit_trigger_row)
    drop_trigger(:depots, :audit_trigger_stm)

    drop_trigger(:depots, :set_created_at)
    drop_function(:depots_set_created_at)
    drop_trigger(:depots, :set_updated_at)
    drop_function(:depots_set_updated_at)
    drop_table(:depots)

    # --- depots
    create_table(:depots, ignore_index_errors: true) do
      primary_key :id
      foreign_key :city_id, :destination_cities, type: :integer
      String :depot_code, null: false
      String :description
      String :edi_code
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:depot_code], name: :depot_unique_code, unique: true
    end

    pgt_created_at(:depots,
                   :created_at,
                   function_name: :depots_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:depots,
                   :updated_at,
                   function_name: :depots_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('depots', true, true, '{updated_at}'::text[]);"

    # --- vehicle_types
    create_table(:vehicle_types, ignore_index_errors: true) do
      primary_key :id
      String :vehicle_type_code, null: false
      String :description
      TrueClass :has_container, default: false
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:vehicle_type_code], name: :vehicle_types_unique_code, unique: true
    end

    pgt_created_at(:vehicle_types,
                   :created_at,
                   function_name: :vehicle_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:vehicle_types,
                   :updated_at,
                   function_name: :vehicle_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('vehicle_types', true, true, '{updated_at}'::text[]);"

    # --- voyage_types
    create_table(:voyage_types, ignore_index_errors: true) do
      primary_key :id
      String :voyage_type_code, null: false
      String :description
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:voyage_type_code], name: :voyage_types_unique_code, unique: true
    end

    pgt_created_at(:voyage_types,
                   :created_at,
                   function_name: :voyage_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:voyage_types,
                   :updated_at,
                   function_name: :voyage_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('voyage_types', true, true, '{updated_at}'::text[]);"

    # --- port_types
    create_table(:port_types, ignore_index_errors: true) do
      primary_key :id
      String :port_type_code, null: false
      String :description
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      # index [:port_type_code], name: :port_types_unique_code, unique: true
    end

    pgt_created_at(:port_types,
                   :created_at,
                   function_name: :port_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:port_types,
                   :updated_at,
                   function_name: :port_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('port_types', true, true, '{updated_at}'::text[]);"

    # --- vessel_types
    create_table(:vessel_types, ignore_index_errors: true) do
      primary_key :id
      foreign_key :voyage_type_id, :voyage_types, type: :integer, null: false
      String :vessel_type_code, null: false
      String :description
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:vessel_type_code], name: :vessel_types_unique_code, unique: true
    end

    pgt_created_at(:vessel_types,
                   :created_at,
                   function_name: :vessel_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:vessel_types,
                   :updated_at,
                   function_name: :vessel_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('vessel_types', true, true, '{updated_at}'::text[]);"

    # --- ports
    create_table(:ports, ignore_index_errors: true) do
      primary_key :id
      foreign_key :port_type_id, :port_types, type: :integer, null: false
      foreign_key :voyage_type_id, :voyage_types, type: :integer, null: false
      foreign_key :city_id, :destination_cities, type: :integer
      String :port_code, null: false
      String :description
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:port_code], name: :ports_unique_code, unique: true
    end

    pgt_created_at(:ports,
                   :created_at,
                   function_name: :ports_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:ports,
                   :updated_at,
                   function_name: :ports_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('ports', true, true, '{updated_at}'::text[]);"

    # --- vessels
    create_table(:vessels, ignore_index_errors: true) do
      primary_key :id
      foreign_key :vessel_type_id, :vessel_types, type: :integer, null: false
      String :vessel_code, null: false
      String :description
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:vessel_code], name: :vessels_unique_code, unique: true
    end

    pgt_created_at(:vessels,
                   :created_at,
                   function_name: :vessels_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:vessels,
                   :updated_at,
                   function_name: :vessels_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('vessels', true, true, '{updated_at}'::text[]);"

    # --- voyages
    create_table(:voyages, ignore_index_errors: true) do
      primary_key :id
      foreign_key :vessel_id, :vessels, type: :integer, null: false
      foreign_key :voyage_type_id, :voyage_types, type: :integer, null: false
      String :voyage_number, null: false
      String :voyage_code
      Integer :year, null: false
      TrueClass :completed, default: false
      DateTime :completed_at
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:voyage_code], name: :voyages_unique_code, unique: true
    end

    pgt_created_at(:voyages,
                   :created_at,
                   function_name: :voyages_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:voyages,
                   :updated_at,
                   function_name: :voyages_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('voyages', true, true, '{updated_at}'::text[]);"

    # --- voyage_ports
    create_table(:voyage_ports, ignore_index_errors: true) do
      primary_key :id
      foreign_key :voyage_id, :voyages, type: :integer, null: false
      foreign_key :port_id, :ports, type: :integer, null: false
      foreign_key :trans_shipment_vessel_id, :vessels, type: :integer
      Date :ata
      Date :atd
      Date :eta
      Date :etd
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:voyage_id, :port_id], name: :voyage_ports_unique_code, unique: true
    end

    pgt_created_at(:voyage_ports,
                   :created_at,
                   function_name: :voyage_ports_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:voyage_ports,
                   :updated_at,
                   function_name: :voyage_ports_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('voyage_ports', true, true, '{updated_at}'::text[]);"
    create_table(:loads, ignore_index_errors: true) do
      primary_key :id
      foreign_key :customer_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :consignee_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :billing_client_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :exporter_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :final_receiver_party_role_id, :party_roles, type: :integer
      foreign_key :final_destination_id, :destination_cities, type: :integer, null: false
      foreign_key :depot_id, :depots, type: :integer, null: false
      foreign_key :pol_voyage_port_id, :voyage_ports, type: :integer, null: false
      foreign_key :pod_voyage_port_id, :voyage_ports, type: :integer, null: false
      String :order_number, null: false
      String :edi_file_name
      String :customer_order_number
      String :customer_reference
      String :exporter_certificate_code
      DateTime :shipped_date
      TrueClass :shipped, default: false
      TrueClass :transfer_load, default: false
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      # index [:code], name: :loads_unique_code, unique: true
    end

    pgt_created_at(:loads,
                   :created_at,
                   function_name: :loads_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:loads,
                   :updated_at,
                   function_name: :loads_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('loads', true, true, '{updated_at}'::text[]);"

    create_table(:load_containers, ignore_index_errors: true) do
      primary_key :id
      foreign_key :load_id, :loads, type: :integer, null: false
      String :container_code, null: false
      String :container_setting
      String :container_vents
      String :container_seal_code, null: false
      BigDecimal :container_temperature_rhine
      BigDecimal :container_temperature_rhine2
      String :internal_container_code, null: false
      BigDecimal :max_gross_mass
      BigDecimal :tare_weight
      BigDecimal :max_payload
      BigDecimal :actual_payload
      String :temp_code
      BigDecimal :verified_gross_mass
      DateTime :verified_gross_mass_date
      String :stack_type
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:internal_container_code], name: :load_containers_unique_code, unique: true
    end

    pgt_created_at(:load_containers,
                   :created_at,
                   function_name: :load_containers_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:load_containers,
                   :updated_at,
                   function_name: :load_containers_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('load_containers', true, true, '{updated_at}'::text[]);"

    create_table(:load_voyages, ignore_index_errors: true) do
      primary_key :id
      foreign_key :load_id, :loads, type: :integer, null: false
      foreign_key :voyage_id, :voyages, type: :integer, null: false
      foreign_key :shipping_line_party_role_id, :party_roles, type: :integer
      foreign_key :shipper_party_role_id, :party_roles, type: :integer
      String :booking_reference
      String :memo_pad
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:load_id, :voyage_id], name: :load_voyages_unique_code, unique: true
    end

    pgt_created_at(:load_voyages,
                   :created_at,
                   function_name: :load_voyages_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:load_voyages,
                   :updated_at,
                   function_name: :load_voyages_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('load_voyages', true, true, '{updated_at}'::text[]);"

    create_table(:load_vehicles, ignore_index_errors: true) do
      primary_key :id
      foreign_key :load_id, :loads, type: :integer, null: false
      foreign_key :vehicle_type_id, :vehicle_types, type: :integer, null: false
      foreign_key :haulier_party_role_id, :party_roles, type: :integer, null: false
      String :vehicle_number, null: false
      BigDecimal :vehicle_weight_out
      String :cooling_type
      String :dispatch_consignment_note_number
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      # index [:id], name: :load_vehicles_unique_code, unique: true
    end

    pgt_created_at(:load_vehicles,
                   :created_at,
                   function_name: :load_vehicles_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:load_vehicles,
                   :updated_at,
                   function_name: :load_vehicles_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('load_vehicles', true, true, '{updated_at}'::text[]);"

  end





  down do
  end
end