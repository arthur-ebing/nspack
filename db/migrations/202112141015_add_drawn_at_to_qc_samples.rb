Sequel.migration do
  up do
    extension :pg_triggers

    create_table(:fruit_defect_categories, ignore_index_errors: true) do
      primary_key :id
      String :defect_category, null: false, unique: true
      String :reporting_description, text: true
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:fruit_defect_categories,
                   :created_at,
                   function_name: :pgt_fruit_defect_categories_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:fruit_defect_categories,
                   :updated_at,
                   function_name: :pgt_fruit_defect_categories_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('fruit_defect_categories', true, true, '{updated_at}'::text[]);"

    alter_table(:fruit_defect_types) do
      add_foreign_key :fruit_defect_category_id, :fruit_defect_categories
      add_column :reporting_description, String
      drop_constraint :fruit_defect_types_fruit_defect_type_name_key
      add_unique_constraint [:fruit_defect_category_id, :fruit_defect_type_name]
    end

    alter_table(:fruit_defects) do
      add_column :reporting_description, String
      add_column :external, TrueClass, default: false
      add_column :active, TrueClass, default: true
      add_column :pre_harvest, TrueClass, default: true
      add_column :post_harvest, TrueClass, default: false
      add_column :severity, String, default: 'Minor', null: false
      add_column :qc_class_2, TrueClass, default: true
      add_column :qc_class_3, TrueClass, default: true
      drop_column :rmt_class_id
    end

    alter_table(:qc_defect_measurements) do
      drop_column :rmt_class_id
      drop_column :qty_fruit_with_percentage
      add_column :qty_class_2, Integer, default: 0, null: false
      add_column :qty_class_3, Integer, default: 0, null: false
    end

    alter_table :qc_samples do
      add_column :drawn_at, DateTime, default: Sequel::CURRENT_TIMESTAMP
    end

    alter_table :qc_sample_types do
      add_column :default_sample_size, Integer
      add_column :required_for_first_orchard_delivery, TrueClass, default: false
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

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_qc_defect_classes(in_qc_test_id integer)
       RETURNS text
       LANGUAGE sql
      AS $function$
        SELECT 'Class 2: ' || SUM(q.qty_class_2)::text || ', Class 3: ' || SUM(q.qty_class_3)::text AS qty
        FROM qc_defect_measurements q
        WHERE qc_test_id = in_qc_test_id
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
      drop_column :required_for_first_orchard_delivery
    end

    alter_table :qc_starch_measurements do
      rename_column :starch_percentage, :starch_precentage
    end

    alter_table(:fruit_defect_types) do
      drop_column :fruit_defect_category_id
      drop_column :reporting_description
      add_unique_constraint :fruit_defect_type_name
    end

    alter_table(:fruit_defects) do
      drop_column :reporting_description
      drop_column :external
      drop_column :active
      drop_column :pre_harvest
      drop_column :post_harvest
      drop_column :severity
      drop_column :qc_class_2
      drop_column :qc_class_3
      add_foreign_key :rmt_class_id, :rmt_classes, null: false
    end

    alter_table(:qc_defect_measurements) do
      add_foreign_key :rmt_class_id, :rmt_classes, null: false
      add_column :qty_fruit_with_percentage, Integer, null: false
      drop_column :qty_class_2
      drop_column :qty_class_3
    end

    drop_trigger(:fruit_defect_categories, :audit_trigger_row)
    drop_trigger(:fruit_defect_categories, :audit_trigger_stm)

    drop_trigger(:fruit_defect_categories, :set_created_at)
    drop_function(:pgt_fruit_defect_categories_set_created_at)
    drop_trigger(:fruit_defect_categories, :set_updated_at)
    drop_function(:pgt_fruit_defect_categories_set_updated_at)
    drop_table(:fruit_defect_categories)

    run 'DROP FUNCTION public.fn_starch_percentages(integer);'
    run 'DROP FUNCTION public.fn_qc_defect_classes(integer);'
  end
end
