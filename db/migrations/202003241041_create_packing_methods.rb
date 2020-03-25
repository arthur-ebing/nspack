require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    create_table(:packing_methods, ignore_index_errors: true) do
      primary_key :id
      String :packing_method_code, null: false
      String :description
      Decimal :actual_count_reduction_factor, null: false
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      index [:packing_method_code], name: :packing_methods_unique_code, unique: true
    end

    pgt_created_at(:packing_methods,
                   :created_at,
                   function_name: :packing_methods_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:packing_methods,
                   :updated_at,
                   function_name: :packing_methods_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('packing_methods', true, true, '{updated_at}'::text[]);"

    alter_table(:product_resource_allocations) do
      add_foreign_key :packing_method_id, :packing_methods, key: [:id]
    end
    alter_table(:carton_labels) do
      add_foreign_key :packing_method_id, :packing_methods, key: [:id]
    end
    alter_table(:cartons) do
      add_foreign_key :packing_method_id, :packing_methods, key: [:id]
    end

    run "INSERT INTO packing_methods (packing_method_code, description, actual_count_reduction_factor) VALUES('NORMAL', 'Normal', 1) ON CONFLICT DO NOTHING;"
    run "UPDATE product_resource_allocations SET packing_method_id = (SELECT id FROM packing_methods WHERE packing_method_code = 'NORMAL') WHERE packing_method_id IS NULL;
         UPDATE carton_labels SET packing_method_id = (SELECT id FROM packing_methods WHERE packing_method_code = 'NORMAL') WHERE packing_method_id IS NULL;
         UPDATE cartons SET packing_method_id = (SELECT id FROM packing_methods WHERE packing_method_code = 'NORMAL') WHERE packing_method_id IS NULL;
        "

    alter_table(:product_resource_allocations) do
      set_column_not_null :packing_method_id
    end
    alter_table(:carton_labels) do
      set_column_not_null :packing_method_id
    end
    alter_table(:cartons) do
      set_column_not_null :packing_method_id
    end
  end

  down do
    alter_table(:product_resource_allocations) do
      drop_column :packing_method_id
    end

    alter_table(:carton_labels) do
      drop_column :packing_method_id
    end

    alter_table(:cartons) do
      drop_column :packing_method_id
    end

    # Drop logging for this table.
    drop_trigger(:packing_methods, :audit_trigger_row)
    drop_trigger(:packing_methods, :audit_trigger_stm)

    drop_trigger(:packing_methods, :set_created_at)
    drop_function(:packing_methods_set_created_at)
    drop_trigger(:packing_methods, :set_updated_at)
    drop_function(:packing_methods_set_updated_at)
    drop_table(:packing_methods)
  end
end
