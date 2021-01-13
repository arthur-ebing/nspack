require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
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

    create_table(:packing_specification_items, ignore_index_errors: true) do
      primary_key :id
      foreign_key :packing_specification_id, :packing_specifications, type: :integer, null: false
      String :description

      foreign_key :pm_bom_id, :pm_boms, type: :integer, null: false
      foreign_key :pm_mark_id, :pm_marks, type: :integer, null: false
      foreign_key :product_setup_id, :product_setups, type: :integer

      foreign_key :tu_labour_product_id, :pm_products, type: :integer
      foreign_key :ru_labour_product_id, :pm_products, type: :integer
      foreign_key :ri_labour_product_id, :pm_products, type: :integer

      column :fruit_sticker_ids, 'int[]'
      column :tu_sticker_ids, 'int[]'
      column :ru_sticker_ids, 'int[]'

      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:packing_specification_items,
                   :created_at,
                   function_name: :packing_specification_items_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:packing_specification_items,
                   :updated_at,
                   function_name: :packing_specification_items_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('packing_specification_items', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:packing_specification_items, :audit_trigger_row)
    drop_trigger(:packing_specification_items, :audit_trigger_stm)

    drop_trigger(:packing_specification_items, :set_created_at)
    drop_function(:packing_specification_items_set_created_at)
    drop_trigger(:packing_specification_items, :set_updated_at)
    drop_function(:packing_specification_items_set_updated_at)
    drop_table(:packing_specification_items)

    drop_trigger(:packing_specifications, :audit_trigger_row)
    drop_trigger(:packing_specifications, :audit_trigger_stm)

    drop_trigger(:packing_specifications, :set_created_at)
    drop_function(:packing_specifications_set_created_at)
    drop_trigger(:packing_specifications, :set_updated_at)
    drop_function(:packing_specifications_set_updated_at)
    drop_table(:packing_specifications)
  end
end
