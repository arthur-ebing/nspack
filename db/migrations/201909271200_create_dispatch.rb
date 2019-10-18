require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

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
  end

  down do

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
  end
end
