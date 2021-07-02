# frozen_string_literal: true

module ProductionApp
  module ProductSetupFactory
    def create_product_setup_template(opts = {})
      id = get_available_factory_record(:product_setup_templates, opts)
      return id unless id.nil?

      cultivar_group_id = create_cultivar_group

      default = {
        template_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        cultivar_group_id: cultivar_group_id,
        cultivar_id: nil,
        packhouse_resource_id: nil,
        production_line_id: nil,
        season_group_id: nil,
        season_id: nil,
        active: true
      }
      DB[:product_setup_templates].insert(default.merge(opts))
    end

    def create_product_setup(opts = {})
      id = get_available_factory_record(:product_setups, opts)
      return id unless id.nil?

      product_setup_template_id = create_product_setup_template
      marketing_variety_id = create_marketing_variety
      std_fruit_size_count_id = create_std_fruit_size_count
      fruit_size_reference_id = create_fruit_size_reference
      marketing_org_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_MARKETER)
      packed_tm_group_id = create_target_market_group
      mark_id = create_mark
      pallet_format_id = create_pallet_format
      cartons_per_pallet_id = create_cartons_per_pallet
      treatment_ids = create_treatment
      grade_id = create_grade
      inventory_code_id = create_inventory_code
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      rmt_class_id = create_rmt_class
      standard_pack_code_id = create_standard_pack
      basic_pack_code_id = create_basic_pack(standard_pack_id: standard_pack_code_id)

      default = {
        product_setup_template_id: product_setup_template_id,
        marketing_variety_id: marketing_variety_id,
        customer_variety_id: nil,
        std_fruit_size_count_id: std_fruit_size_count_id,
        basic_pack_code_id: basic_pack_code_id,
        standard_pack_code_id: standard_pack_code_id,
        fruit_actual_counts_for_pack_id: fruit_actual_counts_for_pack_id,
        fruit_size_reference_id: fruit_size_reference_id,
        marketing_org_party_role_id: marketing_org_party_role_id,
        packed_tm_group_id: packed_tm_group_id,
        mark_id: mark_id,
        inventory_code_id: inventory_code_id,
        pallet_format_id: pallet_format_id,
        cartons_per_pallet_id: cartons_per_pallet_id,
        extended_columns: '{}',
        client_size_reference: Faker::Lorem.unique.word,
        client_product_code: Faker::Lorem.word,
        treatment_ids: "{#{treatment_ids}}",
        marketing_order_number: Faker::Lorem.word,
        sell_by_code: Faker::Lorem.word,
        pallet_label_name: Faker::Lorem.word,
        grade_id: grade_id,
        product_chars: Faker::Lorem.unique.word,
        active: true,
        gtin_code: Faker::Lorem.word,
        rmt_class_id: rmt_class_id
      }
      create_gtin(default.merge(opts))
      DB[:product_setups].insert(default.merge(opts))
    end

    def create_gtin(opts = {})
      default = {
        transaction_number: Faker::Lorem.unique.word,
        gtin_code: Faker::Lorem.word,
        date_to: '2030-01-01 12:00',
        date_from: '2010-01-01 12:00',
        org_code: Faker::Lorem.word,
        commodity_code: Faker::Lorem.word,
        marketing_variety_code: Faker::Lorem.word,
        standard_pack_code: Faker::Lorem.word,
        grade_code: Faker::Lorem.word,
        mark_code: Faker::Lorem.word,
        size_count_code: Faker::Lorem.word,
        inventory_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        commodity_id: DB[:std_fruit_size_counts].where(id: opts[:std_fruit_size_count_id]).get(:commodity_id),
        marketing_variety_id: opts[:marketing_variety_id],
        marketing_org_party_role_id: opts[:marketing_org_party_role_id],
        standard_pack_code_id: opts[:standard_pack_code_id],
        mark_id: opts[:mark_id],
        grade_id: opts[:grade_id],
        inventory_code_id: opts[:inventory_code_id],
        fruit_actual_counts_for_pack_id: opts[:fruit_actual_counts_for_pack_id],
        fruit_size_reference_id: opts[:fruit_size_reference_id]
      }
      DB[:gtins].insert(default)
    end
  end
end
