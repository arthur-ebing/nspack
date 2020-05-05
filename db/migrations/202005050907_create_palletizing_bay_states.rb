require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:palletizing_bay_states, ignore_index_errors: true) do
      primary_key :id
      String :palletizing_robot_code, null: false
      String :scanner_code, null: false
      foreign_key :palletizing_bay_resource_id, :plant_resources
      String :current_state, null: false
      foreign_key :pallet_sequence_id, :pallet_sequences
      foreign_key :determining_carton_id, :cartons
      foreign_key :last_carton_id, :cartons
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:palletizing_robot_code, :scanner_code], name: :palletizing_bay_states_unique_code, unique: true
    end

    pgt_created_at(:palletizing_bay_states,
                   :created_at,
                   function_name: :palletizing_bay_states_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:palletizing_bay_states,
                   :updated_at,
                   function_name: :palletizing_bay_states_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('palletizing_bay_states', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:palletizing_bay_states, :audit_trigger_row)
    drop_trigger(:palletizing_bay_states, :audit_trigger_stm)

    drop_trigger(:palletizing_bay_states, :set_created_at)
    drop_function(:palletizing_bay_states_set_created_at)
    drop_trigger(:palletizing_bay_states, :set_updated_at)
    drop_function(:palletizing_bay_states_set_updated_at)
    drop_table(:palletizing_bay_states)
  end
end
