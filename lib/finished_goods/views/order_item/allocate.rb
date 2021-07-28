# frozen_string_literal: true

module FinishedGoods
  module Orders
    module OrderItem
      class Allocate
        def self.call(id, load_id)
          Crossbeams::Layout::Page.build do |page|
            page.add_notice 'Use the checkboxes and save selection button to select pallets from the grid below.'
            page.add_grid('stock_pallets_for_order_items',
                          "/finished_goods/orders/order_items/#{id}/allocate/#{load_id}/grid",
                          is_multiselect: true,
                          can_be_cleared: true,
                          multiselect_url: "/finished_goods/orders/order_items/#{id}/allocate/#{load_id}",
                          caption: 'Choose pallets')
            page.form(&:no_submit!)
          end
        end
      end
    end
  end
end
