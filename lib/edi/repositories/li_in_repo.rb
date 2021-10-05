# frozen_string_literal: true

module EdiApp
  class LiInRepo < BaseRepo
    def find_commodity_id(commodity_code)
      DB[:commodities].where(code: commodity_code).get(:id)
    end

    def find_actual_count_id(commodity_id, basic_pack_code_id, low_count)
      return nil if commodity_id.nil?
      return nil if basic_pack_code_id.nil?

      std_id = DB[:std_fruit_size_counts].where(commodity_id: commodity_id, size_count_value: low_count).get(:id)
      return nil if std_id.nil?

      DB[:fruit_actual_counts_for_packs].where(basic_pack_code_id: basic_pack_code_id, std_fruit_size_count_id: std_id).get(:id)
    end

    def find_pallet_format_id(base_type, stack_type)
      pallet_base_id = DB[:pallet_bases].where(pallet_base_code: base_type).or(edi_in_pallet_base: base_type).get(:id)
      return nil if pallet_base_id.nil?

      pallet_stack_type_id = DB[:pallet_stack_types].where(stack_type_code: stack_type).get(:id)
      return nil if pallet_stack_type_id.nil?

      DB[:pallet_formats].where(pallet_base_id: pallet_base_id, pallet_stack_type_id: pallet_stack_type_id).get(:id)
    end

    def find_cartons_per_pallet_and_basic_pack_code(pallet_format_id, standard_pack_code_id)
      return [nil, nil] if pallet_format_id.nil? || standard_pack_code_id.nil?

      basic_packs = DB[:basic_packs_standard_packs].where(standard_pack_id: standard_pack_code_id).select_map(:basic_pack_id)
      return [nil, nil] if basic_packs.empty?

      DB[:cartons_per_pallet]
        .where(basic_pack_id: basic_packs, pallet_format_id: pallet_format_id)
        .get(%i[id basic_pack_id])
    end

    def find_customer_payment_term_set(customer_party_role_id, incoterm_id, deal_type_id)
      return nil if customer_party_role_id.nil? || incoterm_id.nil? || deal_type_id.nil?

      customer_id = get_id(:customers, customer_party_role_id: customer_party_role_id)
      DB[:customer_payment_term_sets]
        .where(customer_id: customer_id, incoterm_id: incoterm_id, deal_type_id: deal_type_id)
        .get(:id)
    end

    def latest_values_from_order(customer_party_role_id) # rubocop:disable Metrics/AbcSize
      return failed_response('No customer from LI') if customer_party_role_id.nil?

      customer_id = get_id(:customers, customer_party_role_id: customer_party_role_id)
      order = DB[:orders]
              .where(customer_party_role_id: customer_party_role_id)
              .reverse(:id)
              .first
      return successful_order_found(order, order[:customer_payment_term_set_id]) unless order.nil?

      order = DB[:orders]
              .reverse(:id)
              .first

      customer_payment_term_set_id = DB[:customer_payment_term_sets]
                                     .where(customer_id: customer_id, incoterm_id: order[:incoterm_id], deal_type_id: order[:deal_type_id])
                                     .get(:id)
      return failed_response('No previous orders found') if order.nil? || customer_payment_term_set_id.nil?

      successful_order_found(order, customer_payment_term_set_id)
    end

    def successful_order_found(order, customer_payment_term_set_id)
      success_response('ok', incoterm_id: order[:incoterm_id],
                             deal_type_id: order[:deal_type_id],
                             currency_id: order[:currency_id],
                             order_type_id: order[:order_type_id],
                             customer_payment_term_set_id: customer_payment_term_set_id)
    end

    def find_variant_id(table_name, code)
      DB[:masterfile_variants].where(masterfile_table: table_name.to_s, variant_code: code).get(:masterfile_id)
    end
  end
end
