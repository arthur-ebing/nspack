# frozen_string_literal: true

module ProductionApp
  module ProductSetupFactory
    def create_product_setup_template(opts = {})
      cultivar_group_id = create_cultivar_group
      cultivar_id = create_cultivar
      # plant_resource_id = create_plant_resource
      season_group_id = create_season_group
      season_id = create_season

      default = {
        template_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: cultivar_id,
        packhouse_resource_id: nil,
        production_line_resource_id: nil,
        season_group_id: season_group_id,
        season_id: season_id,
        active: true
      }
      DB[:product_setup_templates].insert(default.merge(opts))
    end

    def create_product_setup(opts = {})  # rubocop:disable Metrics/AbcSize
      product_setup_template_id = create_product_setup_template
      marketing_variety_id = create_marketing_variety
      customer_variety_variety_id = create_customer_variety_variety
      std_fruit_size_count_id = create_std_fruit_size_count
      basic_pack_code_id = create_basic_pack_code
      standard_pack_code_id = create_standard_pack_code
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      fruit_size_reference_id = create_fruit_size_reference
      party_role_id = create_party_role('O', 'MARKETER')[:id]
      mark_id = create_mark
      inventory_code_id = create_inventory_code
      pallet_format_id = create_pallet_format
      cartons_per_pallet_id = create_cartons_per_pallet
      pm_bom_id = create_pm_bom
      target_market_group_id = create_target_market_group
      treatment_ids = create_treatment

      default = {
        product_setup_template_id: product_setup_template_id,
        marketing_variety_id: marketing_variety_id,
        customer_variety_variety_id: customer_variety_variety_id,
        std_fruit_size_count_id: std_fruit_size_count_id,
        basic_pack_code_id: basic_pack_code_id,
        standard_pack_code_id: standard_pack_code_id,
        fruit_actual_counts_for_pack_id: fruit_actual_counts_for_pack_id,
        fruit_size_reference_id: fruit_size_reference_id,
        marketing_org_party_role_id: party_role_id,
        packed_tm_group_id: target_market_group_id,
        mark_id: mark_id,
        inventory_code_id: inventory_code_id,
        pallet_format_id: pallet_format_id,
        cartons_per_pallet_id: cartons_per_pallet_id,
        pm_bom_id: pm_bom_id,
        extended_columns: {},
        client_size_reference: Faker::Lorem.unique.word,
        client_product_code: Faker::Lorem.word,
        treatment_ids: "{#{treatment_ids}}",
        marketing_order_number: Faker::Lorem.word,
        sell_by_code: Faker::Lorem.word,
        pallet_label_name: Faker::Lorem.word,
        active: true
      }
      DB[:product_setups].insert(default.merge(opts))
    end
  end
end
