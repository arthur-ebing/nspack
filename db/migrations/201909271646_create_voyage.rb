require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

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

  end

  down do

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
  end
end
