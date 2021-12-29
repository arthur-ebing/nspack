# frozen_string_literal: true

module ProductionApp
  module GrowerGradingFactory
    def create_grower_grading_rule(opts = {})
      id = get_available_factory_record(:grower_grading_rules, opts)
      return id unless id.nil?

      opts[:packhouse_resource_id] ||= create_plant_resource
      opts[:line_resource_id] ||= create_plant_resource
      opts[:season_id] ||= create_season
      opts[:cultivar_group_id] ||= create_cultivar_group
      opts[:cultivar_id] ||= create_cultivar

      default = {
        rule_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        file_name: Faker::Lorem.word,
        rebin_rule: false,
        active: true,
        created_by: Faker::Lorem.word,
        updated_by: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:grower_grading_rules].insert(default.merge(opts))
    end

    def create_grower_grading_rule_item(opts = {})
      id = get_available_factory_record(:grower_grading_rule_items, opts)
      return id unless id.nil?

      opts[:grower_grading_rule_id] ||= create_grower_grading_rule
      opts[:grade_id] ||= create_grade
      opts[:std_fruit_size_count_id] ||= create_std_fruit_size_count
      opts[:fruit_actual_counts_for_pack_id] ||= create_fruit_actual_counts_for_pack
      opts[:marketing_variety_id] ||= create_marketing_variety
      opts[:rmt_class_id] ||= create_rmt_class
      opts[:rmt_size_id] ||= create_rmt_size
      opts[:fruit_size_reference_id] ||= create_fruit_size_reference
      opts[:inspection_type_id] ||= create_inspection_type
      opts[:commodity_id] ||= create_commodity

      default = {
        legacy_data: BaseRepo.new.hash_for_jsonb_col({}),
        changes: BaseRepo.new.hash_for_jsonb_col({}),
        active: true,
        created_by: Faker::Lorem.unique.word,
        updated_by: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:grower_grading_rule_items].insert(default.merge(opts))
    end

    def create_grower_grading_pool(opts = {})
      id = get_available_factory_record(:grower_grading_pools, opts)
      return id unless id.nil?

      opts[:grower_grading_rule_id] ||= create_grower_grading_rule
      opts[:production_run_id] ||= create_production_run
      opts[:inspection_type_id] ||= create_inspection_type
      opts[:season_id] ||= create_season
      opts[:cultivar_group_id] ||= create_cultivar_group
      opts[:cultivar_id] ||= create_cultivar
      opts[:commodity_id] ||= create_commodity
      opts[:farm_id] ||= create_farm

      default = {
        pool_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        bin_quantity: Faker::Number.number(digits: 4),
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal,
        pro_rata_factor: Faker::Number.decimal,
        legacy_data: BaseRepo.new.hash_for_jsonb_col({}),
        completed: false,
        rule_applied: false,
        active: true,
        created_by: Faker::Lorem.word,
        updated_by: Faker::Lorem.word,
        rule_applied_by: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        rule_applied_at: '2010-01-01 12:00'
      }
      DB[:grower_grading_pools].insert(default.merge(opts))
    end

    def create_grower_grading_carton(opts = {})
      id = get_available_factory_record(:grower_grading_cartons, opts)
      return id unless id.nil?

      opts[:grower_grading_pool_id] ||= create_grower_grading_pool
      opts[:grower_grading_rule_item_id] ||= create_grower_grading_rule_item
      opts[:product_resource_allocation_id] ||= create_product_resource_allocation
      opts[:pm_bom_id] ||= create_pm_bom
      opts[:std_fruit_size_count_id] ||= create_std_fruit_size_count
      opts[:fruit_actual_counts_for_pack_id] ||= create_fruit_actual_counts_for_pack
      opts[:marketing_variety_id] ||= create_marketing_variety
      opts[:rmt_class_id] ||= create_rmt_class
      opts[:fruit_size_reference_id] ||= create_fruit_size_reference
      opts[:inventory_code_id] ||= create_inventory_code
      opts[:grade_id] ||= create_grade
      opts[:marketing_org_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_MARKETER)
      opts[:packed_tm_group_id] ||= create_target_market_group
      opts[:target_market_id] ||= create_target_market

      default = {
        changes_made: BaseRepo.new.hash_for_jsonb_col({}),
        carton_quantity: Faker::Number.number(digits: 4),
        inspected_quantity: Faker::Number.number(digits: 4),
        not_inspected_quantity: Faker::Number.number(digits: 4),
        failed_quantity: Faker::Number.number(digits: 4),
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal,
        completed: false,
        active: true,
        updated_by: Faker::Lorem.unique.word,
        updated_at: '2010-01-01 12:00'
      }
      DB[:grower_grading_cartons].insert(default.merge(opts))
    end

    def create_grower_grading_rebin(opts = {})
      id = get_available_factory_record(:grower_grading_rebins, opts)
      return id unless id.nil?

      opts[:grower_grading_pool_id] ||= create_grower_grading_pool
      opts[:grower_grading_rule_item_id] ||= create_grower_grading_rule_item
      opts[:rmt_class_id] ||= create_rmt_class
      opts[:rmt_size_id] ||= create_rmt_size

      default = {
        changes_made: BaseRepo.new.hash_for_jsonb_col({}),
        rebins_quantity: Faker::Number.number(digits: 4),
        gross_weight: Faker::Number.decimal,
        nett_weight: Faker::Number.decimal,
        pallet_rebin: false,
        completed: false,
        active: true,
        updated_by: Faker::Lorem.unique.word,
        updated_at: '2010-01-01 12:00'
      }
      DB[:grower_grading_rebins].insert(default.merge(opts))
    end
  end
end
