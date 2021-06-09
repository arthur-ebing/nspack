# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Orders
    module OrderItem
      class Allocate
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:order_item, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            form_object = ui_rule.form_object
            page.form_object form_object
            page.form do |form|
              # form.caption 'Order Item'
              form.view_only!
              form.no_submit!

              page.section do |section|
                section.add_grid('stock_pallets_for_loads',
                                 '/list/stock_pallets_for_loads/grid_multi',
                                 caption: 'Choose pallets',
                                 is_multiselect: true,
                                 can_be_cleared: true,
                                 multiselect_url: "/finished_goods/orders/order_items/#{id}/allocate",
                                 multiselect_key: 'allocate_pallets_for_order_item',
                                 height: 20,
                                 multiselect_params: {
                                   id: id,
                                   load_id: form_object.load_id,
                                   packed_tm_group_id: form_object.packed_tm_group_id,
                                   marketing_org_party_role_id: form_object.marketing_org_party_role_id,
                                   target_customer_party_role_id: form_object.target_customer_party_role_id,
                                   commodity_id: form_object.commodity_id,
                                   basic_pack_id: form_object.basic_pack_id,
                                   standard_pack_id: form_object.standard_pack_id,
                                   actual_count_id: form_object.actual_count_id,
                                   size_reference_id: form_object.size_reference_id,
                                   grade_id: form_object.grade_id,
                                   mark_id: form_object.mark_id,
                                   marketing_variety_id: form_object.marketing_variety_id,
                                   inventory_id: form_object.inventory_id,
                                   sell_by_code: form_object.sell_by_code,
                                   pallet_format_id: form_object.pallet_format_id,
                                   pm_mark_id: form_object.pm_mark_id,
                                   pm_bom_id: form_object.pm_bom_id,
                                   rmt_class_id: form_object.rmt_class_id
                                 })
              end
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
