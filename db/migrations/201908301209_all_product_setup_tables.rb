require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:product_setup_templates, ignore_index_errors: true) do
      primary_key :id
      String :template_name, size: 255, null: false
      String :description
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer
      foreign_key :packhouse_resource_id, :plant_resources, type: :integer
      foreign_key :production_line_resource_id, :plant_resources, type: :integer
      foreign_key :season_group_id, :season_groups, type: :integer
      foreign_key :season_id, :seasons, type: :integer
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:template_name], name: :product_setup_templates_unique_code, unique: true
    end

    pgt_created_at(:product_setup_templates,
                   :created_at,
                   function_name: :product_setup_templates_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:product_setup_templates,
                   :updated_at,
                   function_name: :product_setup_templates_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('product_setup_templates', true, true, '{updated_at}'::text[]);"

    create_table(:product_setups, ignore_index_errors: true) do
      primary_key :id
      foreign_key :product_setup_template_id, :product_setup_templates, type: :integer, null: false
      foreign_key :marketing_variety_id, :marketing_varieties, type: :integer, null: false
      foreign_key :customer_variety_variety_id, :customer_variety_varieties, type: :integer
      foreign_key :std_fruit_size_count_id, :std_fruit_size_counts, type: :integer
      foreign_key :basic_pack_code_id, :basic_pack_codes, type: :integer, null: false
      foreign_key :standard_pack_code_id, :standard_pack_codes, type: :integer, null: false
      foreign_key :fruit_actual_counts_for_pack_id, :fruit_actual_counts_for_packs, type: :integer
      foreign_key :fruit_size_reference_id, :fruit_size_references, type: :integer
      foreign_key :marketing_org_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :packed_tm_group_id, :target_market_groups, type: :integer, null: false
      foreign_key :mark_id, :marks, type: :integer, null: false
      foreign_key :inventory_code_id, :inventory_codes, type: :integer
      foreign_key :pallet_format_id, :pallet_formats, type: :integer, null: false
      foreign_key :cartons_per_pallet_id, :cartons_per_pallet, type: :integer, null: false
      foreign_key :pm_bom_id, :pm_boms, type: :integer
      Jsonb :extended_columns
      String :client_size_reference
      String :client_product_code
      column :treatment_ids, 'int[]'
      String :marketing_order_number
      String :sell_by_code
      String :pallet_label_name
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:product_setups,
                   :created_at,
                   function_name: :product_setups_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:product_setups,
                   :updated_at,
                   function_name: :product_setups_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('product_setups', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:product_setups, :audit_trigger_row)
    drop_trigger(:product_setups, :audit_trigger_stm)

    drop_trigger(:product_setups, :set_created_at)
    drop_function(:product_setups_set_created_at)
    drop_trigger(:product_setups, :set_updated_at)
    drop_function(:product_setups_set_updated_at)
    drop_table(:product_setups)

    drop_trigger(:product_setup_templates, :audit_trigger_row)
    drop_trigger(:product_setup_templates, :audit_trigger_stm)

    drop_trigger(:product_setup_templates, :set_created_at)
    drop_function(:product_setup_templates_set_created_at)
    drop_trigger(:product_setup_templates, :set_updated_at)
    drop_function(:product_setup_templates_set_updated_at)
    drop_table(:product_setup_templates)
  end
end
