# frozen_string_literal: true

module FinishedGoodsApp
  module OrderFactory
    def create_order(opts = {})
      id = get_available_factory_record(:orders, opts)
      return id unless id.nil?

      opts[:order_type_id] ||= create_order_type
      opts[:customer_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_CUSTOMER)
      opts[:sales_person_party_role_id] ||= create_party_role(party_type: 'P', name: AppConst::ROLE_SALES_PERSON)
      opts[:contact_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_CUSTOMER_CONTACT_PERSON)
      opts[:currency_id] ||= create_currency
      opts[:deal_type_id] ||= create_deal_type
      opts[:incoterm_id] ||= create_incoterm
      opts[:customer_payment_term_set_id] ||= create_customer_payment_term_set
      opts[:packed_tm_group_id] ||= create_target_market_group
      opts[:target_customer_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_TARGET_CUSTOMER)
      opts[:exporter_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_EXPORTER)
      opts[:final_receiver_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_FINAL_RECEIVER)
      opts[:marketing_org_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_MARKETER)
      default = {
        allocated: false,
        shipped: false,
        completed: false,
        completed_at: '2010-01-01 12:00',
        customer_order_number: Faker::Lorem.unique.word,
        internal_order_number: Faker::Lorem.word,
        remarks: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        pricing_per_kg: false
      }
      DB[:orders].insert(default.merge(opts))
    end

    def create_order_item(opts = {})
      id = get_available_factory_record(:order_items, opts)
      return id unless id.nil?

      opts[:order_id] ||= create_order
      opts[:commodity_id] ||= create_commodity
      opts[:basic_pack_id] ||= create_basic_pack
      opts[:standard_pack_id] ||= create_standard_pack
      opts[:actual_count_id] ||= create_fruit_actual_counts_for_pack
      opts[:size_reference_id] ||= create_fruit_size_reference
      opts[:grade_id] ||= create_grade
      opts[:mark_id] ||= create_mark
      opts[:marketing_variety_id] ||= create_marketing_variety
      opts[:inventory_id] ||= create_inventory_code
      opts[:pallet_format_id] ||= create_pallet_format
      opts[:pm_mark_id] ||= create_pm_mark
      opts[:pm_bom_id] ||= create_pm_bom
      opts[:rmt_class_id] ||= create_rmt_class
      opts[:treatment_id] ||= create_treatment

      default = {
        load_id: nil,
        carton_quantity: Faker::Number.number(digits: 4),
        price_per_carton: Faker::Number.decimal,
        price_per_kg: Faker::Number.decimal,
        sell_by_code: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:order_items].insert(default.merge(opts))
    end
  end
end
