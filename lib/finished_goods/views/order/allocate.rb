# frozen_string_literal: true

module FinishedGoods
  module Orders
    module Order
      class Allocate
        def self.call(id, load_id:, order_item_ids:)
          Crossbeams::Layout::Page.build do |page|
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/finished_goods/orders/orders/#{id}/load/#{load_id}/order_items",
                                  style: :back_button)
            end
            page.add_notice 'Use the checkboxes and save selection button to select pallets from the grid below.'
            page.add_grid('stock_pallets_for_order_items',
                          "/finished_goods/orders/orders/#{id}/load/#{load_id}/grid",
                          is_multiselect: true,
                          can_be_cleared: true,
                          multiselect_url: "/finished_goods/orders/orders/#{id}/load/#{load_id}/allocate",
                          multiselect_params: { order_item_ids: order_item_ids.join(',') },
                          caption: 'Choose pallets')
            page.form(&:no_submit!)
          end
        end
      end
    end
  end
end
