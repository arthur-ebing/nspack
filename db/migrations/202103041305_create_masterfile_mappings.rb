require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:external_masterfile_mappings, ignore_index_errors: true) do
      primary_key :id
      String :masterfile_table, null: false
      String :external_system, null: false
      String :external_code, null: false
      Integer :masterfile_id, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:masterfile_table, :masterfile_id, :external_system], name: :external_masterfile_mappings_unique_code, unique: true
    end

    pgt_created_at(:external_masterfile_mappings,
                   :created_at,
                   function_name: :external_masterfile_mappings_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:external_masterfile_mappings,
                   :updated_at,
                   function_name: :external_masterfile_mappings_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('external_masterfile_mappings', true, true, '{updated_at}'::text[]);"

    run <<~SQL
        CREATE FUNCTION public.fn_external_masterfile_mappings( 
            in_table text,
            in_id integer)
          RETURNS text[] AS
        $BODY$
          SELECT array_agg(concat(external_system, '-', external_code) order by external_system, external_code) AS external_codes
          FROM external_masterfile_mappings
          WHERE masterfile_table = in_table
            AND masterfile_id = in_id
        $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
        ALTER FUNCTION public.fn_external_masterfile_mappings(text, integer)
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
        DROP FUNCTION public.fn_external_masterfile_mappings(text, integer);
    SQL

    # Drop logging for this table.
    drop_trigger(:external_masterfile_mappings, :audit_trigger_row)
    drop_trigger(:external_masterfile_mappings, :audit_trigger_stm)

    drop_trigger(:external_masterfile_mappings, :set_created_at)
    drop_function(:external_masterfile_mappings_set_created_at)
    drop_trigger(:external_masterfile_mappings, :set_updated_at)
    drop_function(:external_masterfile_mappings_set_updated_at)
    drop_table(:external_masterfile_mappings)
  end
end
