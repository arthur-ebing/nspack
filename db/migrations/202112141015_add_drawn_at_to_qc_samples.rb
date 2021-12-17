Sequel.migration do
  up do
    alter_table :qc_samples do
      add_column :drawn_at, DateTime, default: Sequel::CURRENT_TIMESTAMP
    end

    alter_table :qc_sample_types do
      add_column :default_sample_size, Integer
    end

    alter_table :qc_tests do
      set_column_allow_null :qc_measurement_type_id
    end

    alter_table :qc_starch_measurements do
      rename_column :starch_precentage, :starch_percentage
    end

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_starch_percentages(in_qc_test_id integer)
       RETURNS text
       LANGUAGE sql
      AS $function$
        SELECT '[' || string_agg(qp.perc_qty, '], [') || ']' AS percentages
      FROM (
        SELECT starch_percentage::text || '%: ' || qty_fruit_with_percentage::TEXT AS perc_qty
        FROM qc_starch_measurements qsm
        WHERE qc_test_id = in_qc_test_id
        AND qty_fruit_with_percentage <> 0
        ORDER BY starch_percentage) qp
      $function$
      ;
    SQL
  end

  down do
    alter_table :qc_samples do
      drop_column :drawn_at
    end

    alter_table :qc_sample_types do
      drop_column :default_sample_size
    end

    alter_table :qc_starch_measurements do
      rename_column :starch_percentage, :starch_precentage
    end
  end
end
