require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
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

    rename_table(:external_masterfile_mappings, :masterfile_transformations)

    pgt_created_at(:masterfile_transformations,
                   :created_at,
                   function_name: :masterfile_transformations_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:masterfile_transformations,
                   :updated_at,
                   function_name: :masterfile_transformations_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('masterfile_transformations', true, true, '{updated_at}'::text[]);"

    run <<~SQL
        CREATE FUNCTION public.fn_masterfile_transformations(
            in_table text,
            in_id integer)
          RETURNS text[] AS
        $BODY$
          SELECT array_agg(concat(external_system, '-', external_code) order by external_system, external_code) AS external_codes
          FROM masterfile_transformations
          WHERE masterfile_table = in_table
            AND masterfile_id = in_id
        $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
        ALTER FUNCTION public.fn_masterfile_transformations(text, integer)
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP FUNCTION public.fn_masterfile_transformations(text, integer);
    SQL

    # Drop logging for this table.
    drop_trigger(:masterfile_transformations, :audit_trigger_row)
    drop_trigger(:masterfile_transformations, :audit_trigger_stm)

    drop_trigger(:masterfile_transformations, :set_created_at)
    drop_function(:masterfile_transformations_set_created_at)
    drop_trigger(:masterfile_transformations, :set_updated_at)
    drop_function(:masterfile_transformations_set_updated_at)


    rename_table(:masterfile_transformations, :external_masterfile_mappings)

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
end
