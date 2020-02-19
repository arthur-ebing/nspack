require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:personnel_identifiers, ignore_index_errors: true) do
      primary_key :id
      String :hardware_type, null: false
      String :identifier, null: false
      Date :available_from, default: Sequel.lit('CURRENT_DATE')
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:identifier], name: :personnel_identifiers_unique_code, unique: true
    end

    pgt_created_at(:personnel_identifiers,
                   :created_at,
                   function_name: :personnel_identifiers_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:personnel_identifiers,
                   :updated_at,
                   function_name: :personnel_identifiers_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('personnel_identifiers', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:personnel_identifiers, :audit_trigger_row)
    drop_trigger(:personnel_identifiers, :audit_trigger_stm)

    drop_trigger(:personnel_identifiers, :set_created_at)
    drop_function(:personnel_identifiers_set_created_at)
    drop_trigger(:personnel_identifiers, :set_updated_at)
    drop_function(:personnel_identifiers_set_updated_at)
    drop_table(:personnel_identifiers)
  end
end
