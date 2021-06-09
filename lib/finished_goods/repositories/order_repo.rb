# frozen_string_literal: true

module FinishedGoodsApp
  class OrderRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :orders,
                     label: :internal_order_number,
                     value: :id,
                     order_by: :internal_order_number
    build_inactive_select :orders,
                          label: :internal_order_number,
                          value: :id,
                          order_by: :internal_order_number

    crud_calls_for :orders, name: :order, exclude: [:delete]

    build_for_select :order_items,
                     label: :sell_by_code,
                     value: :id,
                     order_by: :sell_by_code
    build_inactive_select :order_items,
                          label: :sell_by_code,
                          value: :id,
                          order_by: :sell_by_code

    crud_calls_for :order_items, name: :order_item, exclude: [:delete]

    def find_order(id)
      hash = find_with_association(
        :orders, id,
        parent_tables: [
          { parent_table: :order_types, foreign_key: :order_type_id, flatten_columns: { order_type: :order_type } },
          { parent_table: :currencies, foreign_key: :currency_id, flatten_columns: { currency: :currency } },
          { parent_table: :target_market_groups, foreign_key: :packed_tm_group_id, flatten_columns: { target_market_group_name: :packed_tm_group } },
          { parent_table: :deal_types, foreign_key: :deal_type_id, flatten_columns: { deal_type: :deal_type } },
          { parent_table: :incoterms, foreign_key: :incoterm_id, flatten_columns: { incoterm: :incoterm } }
        ],
        lookup_functions: [
          { function: :fn_party_role_name, args: [:target_customer_party_role_id], col_name: :target_customer },
          { function: :fn_party_role_name, args: [:exporter_party_role_id], col_name: :exporter },
          { function: :fn_party_role_name, args: [:customer_party_role_id], col_name: :customer },
          { function: :fn_party_role_name, args: [:contact_party_role_id], col_name: :contact },
          { function: :fn_party_role_name, args: [:final_receiver_party_role_id], col_name: :final_receiver },
          { function: :fn_party_role_name, args: [:marketing_org_party_role_id], col_name: :marketing_org }
        ]
      )
      return nil if hash.nil?

      hash[:order_id] = id
      hash[:order_number] = hash[:internal_order_number]
      hash[:contact_person_ids] = get_value(:customers, :contact_person_ids, customer_party_role_id: hash[:customer_party_role_id])
      hash[:customer_payment_term_set] = MasterfilesApp::FinanceRepo.new.for_select_customer_payment_term_sets(
        where: { Sequel[:customer_payment_term_sets][:id] => hash[:customer_payment_term_set_id] }, active: nil
      ).flatten.first
      Order.new(hash)
    end

    def find_order_item(id)
      hash = find_with_association(
        :order_items, id,
        parent_tables: [
          { parent_table: :orders, foreign_key: :order_id,
            flatten_columns: { packed_tm_group_id: :packed_tm_group_id,
                               marketing_org_party_role_id: :marketing_org_party_role_id,
                               target_customer_party_role_id: :target_customer_party_role_id } },
          { parent_table: :fruit_actual_counts_for_packs, foreign_key: :actual_count_id,
            flatten_columns: { actual_count_for_pack: :actual_count } },
          { parent_table: :basic_pack_codes, foreign_key: :basic_pack_id,
            flatten_columns: { basic_pack_code: :basic_pack } },
          { parent_table: :standard_pack_codes, foreign_key: :standard_pack_id,
            flatten_columns: { standard_pack_code: :standard_pack } },
          { parent_table: :commodities, foreign_key: :commodity_id,
            flatten_columns: { code: :commodity } },
          { parent_table: :grades, foreign_key: :grade_id,
            flatten_columns: { grade_code: :grade } },
          { parent_table: :inventory_codes, foreign_key: :inventory_id,
            flatten_columns: { inventory_code: :inventory } },
          { parent_table: :marks, foreign_key: :mark_id,
            flatten_columns: { mark_code: :mark } },
          { parent_table: :marketing_varieties, foreign_key: :marketing_variety_id,
            flatten_columns: { marketing_variety_code: :marketing_variety } },
          { parent_table: :fruit_size_references, foreign_key: :size_reference_id,
            flatten_columns: { size_reference: :size_reference } },
          { parent_table: :pallet_formats, foreign_key: :pallet_format_id,
            flatten_columns: { description: :pallet_format } },
          { parent_table: :pm_boms, foreign_key: :pm_bom_id,
            flatten_columns: { bom_code: :pkg_bom } },
          { parent_table: :pm_marks, foreign_key: :pm_mark_id,
            flatten_columns: { description: :pkg_mark } },
          { parent_table: :rmt_classes, foreign_key: :rmt_class_id,
            flatten_columns: { rmt_class_code: :rmt_class } },
          { parent_table: :treatments, foreign_key: :treatment_id,
            flatten_columns: { treatment_code: :treatment } }
        ],
        lookup_functions: [
          { function: :fn_current_status, args: ['order_items', :id], col_name: :status }
        ]
      )
      return nil if hash.nil?

      hash[:order] = get(:orders, hash[:order_id], :internal_order_number)
      OrderItem.new(hash)
    end

    def delete_order(id)
      DB[:orders_loads].where(order_id: id).delete
      delete(:orders, id)
    end

    def delete_order_item(id)
      DB[:order_items_pallet_sequences].where(order_item_id: id).delete
      delete(:order_items, id)
    end

    def inline_update_order_item(id, params)
      inline_columns = %w[carton_quantity price_per_carton price_per_kg]

      case params[:column_name]
      when *inline_columns
        column = params[:column_name]
        value = params[:column_value]
      else
        raise Crossbeams::InfoError, "There is no handler for changed column #{params[:column_name]}"
      end

      update(:order_items, id, { column => value })
    end

    def allocate_to_order_item(id, allocate_sequence_ids, user)
      load_id = get(:order_items, id, :load_id)
      pallet_sequence_ids = select_values(:order_items_pallet_sequences, :pallet_sequence_id, order_item_id: id)
      current_allocation = select_values(:pallet_sequences, :pallet_number, id: pallet_sequence_ids)
      new_allocation = select_values(:pallet_sequences, :pallet_number, id: allocate_sequence_ids)

      LoadRepo.new.unallocate_pallets(current_allocation - new_allocation, user)
      LoadRepo.new.allocate_pallets(load_id, new_allocation - current_allocation, user)
      FinishedGoodsApp::ProcessOrderLines.call(user, load_id: load_id)
    end
  end
end
