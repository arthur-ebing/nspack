require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:masterfile_variants, ignore_index_errors: true) do
      primary_key :id
      String :masterfile_table, null: false
      String :code, null: false
      Integer :masterfile_id, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:masterfile_table, :code], name: :masterfile_variants_unique_code, unique: true
    end

    pgt_created_at(:masterfile_variants,
                   :created_at,
                   function_name: :masterfile_variants_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:masterfile_variants,
                   :updated_at,
                   function_name: :masterfile_variants_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('masterfile_variants', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:masterfile_variants, :audit_trigger_row)
    drop_trigger(:masterfile_variants, :audit_trigger_stm)

    drop_trigger(:masterfile_variants, :set_created_at)
    drop_function(:masterfile_variants_set_created_at)
    drop_trigger(:masterfile_variants, :set_updated_at)
    drop_function(:masterfile_variants_set_updated_at)
    drop_table(:masterfile_variants)
  end
end
