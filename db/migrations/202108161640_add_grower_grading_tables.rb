require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:grower_grading_rules, ignore_index_errors: true) do
      primary_key :id
      String :rule_name, null: false
      String :description
      String :file_name
      foreign_key :packhouse_resource_id, :plant_resources, type: :integer
      foreign_key :line_resource_id, :plant_resources, type: :integer
      foreign_key :season_id, :seasons, type: :integer
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer
      TrueClass :rebin_rule, default: false
      TrueClass :active, default: true
      String :created_by
      String :updated_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:rule_name], name: :grower_grading_rules_unique_code, unique: true
    end

    pgt_created_at(:grower_grading_rules,
                   :created_at,
                   function_name: :grower_grading_rules_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:grower_grading_rules,
                   :updated_at,
                   function_name: :grower_grading_rules_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('grower_grading_rules', true, true, '{updated_at}'::text[]);"

    # GROWER GRADING RULE ITEMS
    create_table(:grower_grading_rule_items, ignore_index_errors: true) do
      primary_key :id
      foreign_key :grower_grading_rule_id, :grower_grading_rules, type: :integer, null: false
      foreign_key :commodity_id, :commodities, type: :integer
      foreign_key :marketing_variety_id, :marketing_varieties, type: :integer
      foreign_key :grade_id, :grades, type: :integer
      foreign_key :std_fruit_size_count_id, :std_fruit_size_counts, type: :integer
      foreign_key :fruit_actual_counts_for_pack_id, :fruit_actual_counts_for_packs, type: :integer
      foreign_key :fruit_size_reference_id, :fruit_size_references, type: :integer
      foreign_key :inspection_type_id, :inspection_types, type: :integer
      foreign_key :rmt_class_id, :rmt_classes, type: :integer
      foreign_key :rmt_size_id, :rmt_sizes, type: :integer
      Jsonb :legacy_data
      Jsonb :changes
      TrueClass :active, default: true
      String :created_by
      String :updated_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:grower_grading_rule_items,
                   :created_at,
                   function_name: :grower_grading_rule_items_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:grower_grading_rule_items,
                   :updated_at,
                   function_name: :grower_grading_rule_items_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('grower_grading_rule_items', true, true, '{updated_at}'::text[]);"

    # GROWER GRADING POOLS
    create_table(:grower_grading_pools, ignore_index_errors: true) do
      primary_key :id
      foreign_key :grower_grading_rule_id, :grower_grading_rules, type: :integer
      String :pool_name, null: false
      String :description
      foreign_key :production_run_id, :production_runs, type: :integer
      foreign_key :season_id, :seasons, type: :integer
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer, null: false
      foreign_key :cultivar_id, :cultivars, type: :integer
      foreign_key :commodity_id, :commodities, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :inspection_type_id, :inspection_types, type: :integer
      Integer :bin_quantity
      Decimal :gross_weight
      Decimal :nett_weight
      Decimal :pro_rata_factor
      Jsonb :legacy_data
      TrueClass :completed, default: false
      TrueClass :rule_applied, default: false
      TrueClass :active, default: true
      String :created_by
      String :updated_by
      String :rule_applied_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
      DateTime :rule_applied_at

      index [:pool_name], name: :grower_grading_pools_unique_code, unique: true
    end

    pgt_created_at(:grower_grading_pools,
                   :created_at,
                   function_name: :grower_grading_pools_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:grower_grading_pools,
                   :updated_at,
                   function_name: :grower_grading_pools_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('grower_grading_pools', true, true, '{updated_at}'::text[]);"

    # GROWER GRADING CARTONS
    create_table(:grower_grading_cartons, ignore_index_errors: true) do
      primary_key :id
      foreign_key :grower_grading_pool_id, :grower_grading_pools, type: :integer, null: false
      foreign_key :grower_grading_rule_item_id, :grower_grading_rule_items, type: :integer
      foreign_key :product_resource_allocation_id, :product_resource_allocations, type: :integer
      foreign_key :pm_bom_id, :pm_boms, type: :integer
      foreign_key :std_fruit_size_count_id, :std_fruit_size_counts, type: :integer
      foreign_key :fruit_actual_counts_for_pack_id, :fruit_actual_counts_for_packs, type: :integer
      foreign_key :marketing_org_party_role_id, :party_roles, type: :integer, null: false
      foreign_key :packed_tm_group_id, :target_market_groups, type: :integer, null: false
      foreign_key :target_market_id, :target_markets, type: :integer
      foreign_key :inventory_code_id, :inventory_codes, type: :integer
      foreign_key :rmt_class_id, :rmt_classes, type: :integer
      foreign_key :grade_id, :grades, type: :integer, null: false
      foreign_key :marketing_variety_id, :marketing_varieties, type: :integer, null: false
      foreign_key :fruit_size_reference_id, :fruit_size_references, type: :integer
      Jsonb :changes_made
      Integer :carton_quantity
      Integer :inspected_quantity
      Integer :not_inspected_quantity
      Integer :failed_quantity
      Decimal :gross_weight
      Decimal :nett_weight
      TrueClass :completed, default: false
      TrueClass :active, default: true
      String :updated_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:grower_grading_cartons,
                   :created_at,
                   function_name: :grower_grading_cartons_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:grower_grading_cartons,
                   :updated_at,
                   function_name: :grower_grading_cartons_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('grower_grading_cartons', true, true, '{updated_at}'::text[]);"

    # GROWER GRADING REBINS
    create_table(:grower_grading_rebins, ignore_index_errors: true) do
      primary_key :id
      foreign_key :grower_grading_pool_id, :grower_grading_pools, type: :integer, null: false
      foreign_key :grower_grading_rule_item_id, :grower_grading_rule_items, type: :integer
      foreign_key :rmt_class_id, :rmt_classes, type: :integer
      foreign_key :rmt_size_id, :rmt_sizes, type: :integer
      Jsonb :changes_made
      Integer :rebins_quantity
      Decimal :gross_weight
      Decimal :nett_weight
      TrueClass :pallet_rebin, default: false
      TrueClass :completed, default: false
      TrueClass :active, default: true
      String :updated_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:grower_grading_rebins,
                   :created_at,
                   function_name: :grower_grading_rebins_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:grower_grading_rebins,
                   :updated_at,
                   function_name: :grower_grading_rebins_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('grower_grading_rebins', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:grower_grading_rebins, :audit_trigger_row)
    drop_trigger(:grower_grading_rebins, :audit_trigger_stm)

    drop_trigger(:grower_grading_rebins, :set_created_at)
    drop_function(:grower_grading_rebins_set_created_at)
    drop_trigger(:grower_grading_rebins, :set_updated_at)
    drop_function(:grower_grading_rebins_set_updated_at)
    drop_table(:grower_grading_rebins)

    drop_trigger(:grower_grading_cartons, :audit_trigger_row)
    drop_trigger(:grower_grading_cartons, :audit_trigger_stm)

    drop_trigger(:grower_grading_cartons, :set_created_at)
    drop_function(:grower_grading_cartons_set_created_at)
    drop_trigger(:grower_grading_cartons, :set_updated_at)
    drop_function(:grower_grading_cartons_set_updated_at)
    drop_table(:grower_grading_cartons)

    drop_trigger(:grower_grading_pools, :audit_trigger_row)
    drop_trigger(:grower_grading_pools, :audit_trigger_stm)

    drop_trigger(:grower_grading_pools, :set_created_at)
    drop_function(:grower_grading_pools_set_created_at)
    drop_trigger(:grower_grading_pools, :set_updated_at)
    drop_function(:grower_grading_pools_set_updated_at)
    drop_table(:grower_grading_pools)

    drop_trigger(:grower_grading_rule_items, :audit_trigger_row)
    drop_trigger(:grower_grading_rule_items, :audit_trigger_stm)

    drop_trigger(:grower_grading_rule_items, :set_created_at)
    drop_function(:grower_grading_rule_items_set_created_at)
    drop_trigger(:grower_grading_rule_items, :set_updated_at)
    drop_function(:grower_grading_rule_items_set_updated_at)
    drop_table(:grower_grading_rule_items)

    drop_trigger(:grower_grading_rules, :audit_trigger_row)
    drop_trigger(:grower_grading_rules, :audit_trigger_stm)

    drop_trigger(:grower_grading_rules, :set_created_at)
    drop_function(:grower_grading_rules_set_created_at)
    drop_trigger(:grower_grading_rules, :set_updated_at)
    drop_function(:grower_grading_rules_set_updated_at)
    drop_table(:grower_grading_rules)
  end
end
