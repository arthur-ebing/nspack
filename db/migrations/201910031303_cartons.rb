require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:cartons, ignore_index_errors: true) do
      primary_key :id
      foreign_key :production_run_id, :production_runs, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :puc_id, :pucs, type: :integer, null: false
      foreign_key :orchard_id, :orchards, type: :integer, null: false
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer
      foreign_key :product_resource_allocation_id, :product_resource_allocations, type: :integer, null: false
      foreign_key :packhouse_resource_id, :plant_resources, type: :integer, null: false
      foreign_key :production_line_resource_id, :plant_resources, type: :integer, null: false
      foreign_key :season_id, :seasons, type: :integer, null: false
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
      foreign_key :inventory_code_id, :inventory_codes, type: :integer, null: false
      foreign_key :pallet_format_id, :pallet_formats, type: :integer, null: false
      foreign_key :cartons_per_pallet_id, :cartons_per_pallet, type: :integer, null: false
      foreign_key :pm_bom_id, :pm_boms, type: :integer
      Jsonb :extended_columns
      String :client_size_reference
      String :client_product_code
      column :treatment_ids, 'int[]'
      String :marketing_order_number
      foreign_key :fruit_sticker_pm_product_id, :pm_products, type: :integer
      foreign_key :pm_type_id, :pm_types, type: :integer
      foreign_key :pm_subtype_id, :pm_subtypes, type: :integer
      foreign_key :carton_label_id, :carton_labels, type: :integer, null: false
      Decimal :gross_weight
      Decimal :nett_weight
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:cartons,
                   :created_at,
                   function_name: :cartons_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:cartons,
                   :updated_at,
                   function_name: :cartons_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('cartons', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:cartons, :audit_trigger_row)
    drop_trigger(:cartons, :audit_trigger_stm)

    drop_trigger(:cartons, :set_created_at)
    drop_function(:cartons_set_created_at)
    drop_trigger(:cartons, :set_updated_at)
    drop_function(:cartons_set_updated_at)
    drop_table(:cartons)
  end
end
