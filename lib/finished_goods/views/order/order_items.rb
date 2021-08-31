# frozen_string_literal: true

module FinishedGoods
  module Orders
    module Order
      class OrderItems
        def self.call(order_id:, load_id:)
          Crossbeams::Layout::Page.build do |page|
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/finished_goods/orders/orders/#{order_id}",
                                  style: :back_button)
            end
            page.add_notice 'Use the checkboxes and save selection button to select order items from the grid below.'
            page.add_grid('load_order_items',
                          "/finished_goods/orders/orders/#{order_id}/order_items_grid?for_multiselect=true",
                          caption: 'Order Items',
                          is_multiselect: true,
                          multiselect_url: "/finished_goods/orders/orders/#{order_id}/load/#{load_id}/order_items")
          end
        end
      end
    end
  end
end
