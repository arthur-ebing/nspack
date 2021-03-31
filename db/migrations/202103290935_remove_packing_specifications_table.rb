Sequel.migration do
  up do
    alter_table(:production_runs) do
      drop_column :packing_specification_id
    end

    alter_table(:packing_specification_items) do
      drop_column :packing_specification_id
      set_column_not_null :product_setup_id
    end

    drop_trigger(:packing_specifications, :audit_trigger_row)
    drop_trigger(:packing_specifications, :audit_trigger_stm)

    drop_trigger(:packing_specifications, :set_created_at)
    drop_function(:packing_specifications_set_created_at)
    drop_trigger(:packing_specifications, :set_updated_at)
    drop_function(:packing_specifications_set_updated_at)
    drop_table(:packing_specifications)

  end

  down do

    extension :pg_triggers
    create_table(:packing_specifications, ignore_index_errors: true) do
      primary_key :id
      foreign_key :product_setup_template_id, :product_setup_templates, type: :integer, null: false
      String :packing_specification_code, null: false
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:packing_specifications,
                   :created_at,
                   function_name: :packing_specifications_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:packing_specifications,
                   :updated_at,
                   function_name: :packing_specifications_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('packing_specifications', true, true, '{updated_at}'::text[]);"

    alter_table(:production_runs) do
      add_column :packing_specification_id, :Integer
    end

    alter_table(:packing_specification_items) do
      add_foreign_key :packing_specification_id, :packing_specifications, key: [:id]
      set_column_allow_null :product_setup_id
    end

  end
end
