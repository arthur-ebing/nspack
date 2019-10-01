require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    create_table(:loads, ignore_index_errors: true) do
      primary_key :id
      foreign_key :depot_location_id, :locations, type: :integer, null: false
      foreign_key :customer_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :consignee_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :billing_client_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :exporter_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :final_receiver_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :final_destination_id, :destination_cities, type: :integer, null: false
      foreign_key :pol_voyage_port_id, :voyage_ports, type: :integer, null: false
      foreign_key :pod_voyage_port_id, :voyage_ports, type: :integer, null: false
      String :order_number, null: false
      String :edi_file_name
      String :customer_order_number, null: false
      String :customer_reference
      String :exporter_certificate_code
      DateTime :shipped_date, null: false
      TrueClass :shipped, default: false
      TrueClass :transfer_load, default: false
      TrueClass :active, default: true
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
      TrueClass :active, default: true
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
      foreign_key :shipping_line_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :shipper_party_role_id, :party_roles, type: :integer, null: false
      String :booking_reference, null: false
      String :memo_pad
      TrueClass :active, default: true
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
      TrueClass :active, default: true
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
  end
end
