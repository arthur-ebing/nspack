# frozen_string_literal: true

module FinishedGoods
  module Orders
    module OrderItem
      class Load
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:order_item, :allocate, id: id, form_values: form_values)
          rules   = ui_rule.compile
          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors

            # page.section do |section|
            #   section.add_control(control_type: :link,
            #                       text: 'Back',
            #                       url: "/finished_goods/orders/orders/#{ui_rule.form_object.order_id}",
            #                       style: :back_button)
            # end

            # page.add_notice 'Use the checkboxes and save selection button to select a load from the grid below.'
            page.form do |form|
              form.caption 'Select Load'
              form.action "/finished_goods/orders/order_items/#{id}/allocate"
              form.remote!
              form.add_field :load_id
            end

            # Ideally I would have liked to use a grid to select the load

            # page.add_grid('stock_pallets_for_order_items',
            #               "/finished_goods/orders/order_items/#{id}/allocate/grid",
            #               is_multiselect: true,
            #               can_be_cleared: true,
            #               multiselect_url: "/finished_goods/orders/order_items/#{id}/allocate",
            #               caption: 'Choose pallets'
          end
        end
      end
    end
  end
end
