# frozen_string_literal: true

module FinishedGoodsApp
  module OrderFactory
    def create_orders_loads(opts = {})
      load_id = create_load
      order_id = create_order

      default = {
        load_id: load_id,
        order_id: order_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:orders_loads].insert(default.merge(opts))
    end

    def create_order(opts = {}) # rubocop:disable Metrics/AbcSize
      order_type_id = create_order_type
      customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_CUSTOMER)
      contact_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_CUSTOMER_CONTACT_PERSON)
      currency_id = create_currency
      deal_type_id = create_deal_type
      incoterm_id = create_incoterm
      customer_payment_term_set_id = create_customer_payment_term_set
      target_market_group_id = create_target_market_group
      target_customer_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_TARGET_CUSTOMER)
      exporter_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_EXPORTER)
      final_receiver_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_FINAL_RECEIVER)
      marketing_org_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_MARKETER)

      default = {
        order_type_id: order_type_id,
        customer_party_role_id: customer_party_role_id,
        contact_party_role_id: contact_party_role_id,
        currency_id: currency_id,
        deal_type_id: deal_type_id,
        incoterm_id: incoterm_id,
        customer_payment_term_set_id: customer_payment_term_set_id,
        target_customer_party_role_id: target_customer_party_role_id,
        exporter_party_role_id: exporter_party_role_id,
        packed_tm_group_id: target_market_group_id,
        final_receiver_party_role_id: final_receiver_party_role_id,
        marketing_org_party_role_id: marketing_org_party_role_id,
        allocated: false,
        shipped: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        customer_order_number: Faker::Lorem.unique.word,
        internal_order_number: Faker::Lorem.word,
        remarks: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:orders].insert(default.merge(opts))
    end

    def create_order_item(opts = {}) # rubocop:disable Metrics/AbcSize
      order_id = create_order
      commodity_id = create_commodity
      basic_pack_code_id = create_basic_pack
      standard_pack_code_id = create_standard_pack
      fruit_actual_counts_for_pack_id = create_fruit_actual_counts_for_pack
      fruit_size_reference_id = create_fruit_size_reference
      grade_id = create_grade
      mark_id = create_mark
      marketing_variety_id = create_marketing_variety
      inventory_code_id = create_inventory_code
      pallet_format_id = create_pallet_format
      pm_mark_id = create_pm_mark
      pm_bom_id = create_pm_bom
      rmt_class_id = create_rmt_class
      treatment_id = create_treatment

      default = {
        order_id: order_id,
        load_id: nil,
        commodity_id: commodity_id,
        basic_pack_id: basic_pack_code_id,
        standard_pack_id: standard_pack_code_id,
        actual_count_id: fruit_actual_counts_for_pack_id,
        size_reference_id: fruit_size_reference_id,
        grade_id: grade_id,
        mark_id: mark_id,
        marketing_variety_id: marketing_variety_id,
        inventory_id: inventory_code_id,
        carton_quantity: Faker::Number.number(digits: 4),
        price_per_carton: Faker::Number.decimal,
        price_per_kg: Faker::Number.decimal,
        sell_by_code: Faker::Lorem.unique.word,
        pallet_format_id: pallet_format_id,
        pm_mark_id: pm_mark_id,
        pm_bom_id: pm_bom_id,
        rmt_class_id: rmt_class_id,
        treatment_id: treatment_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:order_items].insert(default.merge(opts))
    end
  end
end
