require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:pm_marks, ignore_index_errors: true) do
      primary_key :id
      foreign_key :mark_id, :marks, type: :integer, null: false
      column :packaging_marks, 'text[]'
      String :description, null: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:mark_id], name: :pm_mark_unique_fruitspec_mark, unique: true
    end

    pgt_created_at(:pm_marks,
                   :created_at,
                   function_name: :pm_marks_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:pm_marks,
                   :updated_at,
                   function_name: :pm_marks_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('pm_marks', true, true, '{updated_at}'::text[]);"

  end

  down do

    # Drop logging for this table.
    drop_trigger(:pm_marks, :audit_trigger_row)
    drop_trigger(:pm_marks, :audit_trigger_stm)

    drop_trigger(:pm_marks, :set_created_at)
    drop_function(:pm_marks_set_created_at)
    drop_trigger(:pm_marks, :set_updated_at)
    drop_function(:pm_marks_set_updated_at)
    drop_table(:pm_marks)
  end
end
