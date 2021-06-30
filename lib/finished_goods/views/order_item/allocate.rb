# frozen_string_literal: true

module FinishedGoods
  module Orders
    module OrderItem
      class Allocate
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:order_item, :allocate, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_notice 'Use the checkboxes and save selection button to select pallets from the grid below. - Or add pallets by listing pallet numbers in the box above and pressing Allocate pasted pallets.'
            page.add_grid('stock_pallets_for_order_items',
                          "/finished_goods/orders/order_items/#{id}/allocate/grid",
                          is_multiselect: true,
                          can_be_cleared: true,
                          multiselect_url: "/finished_goods/orders/order_items/#{id}/allocate",
                          caption: 'Choose pallets')
            page.form(&:no_submit!)
          end

          layout
        end
      end
    end
  end
end
