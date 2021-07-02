# frozen_string_literal: true

module FinishedGoods
  module Orders
    module Order
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:order, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              ui_rule.form_object.instance_controls.each do |control|
                section.add_control(control)
              end
            end
            page.form do |form|
              # form.caption 'Order'
              form.view_only!
              form.no_submit!
              form.fold_up do |fold|
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :order_type
                    col.add_field :customer
                    col.add_field :contact
                    col.add_field :currency
                    col.add_field :deal_type
                    col.add_field :incoterm
                    col.add_field :customer_payment_term_set
                  end
                  row.column do |col|
                    col.add_field :target_customer
                    col.add_field :exporter
                    col.add_field :final_receiver
                    col.add_field :marketing_org
                    col.add_field :packed_tm_group
                    col.add_field :customer_order_number
                    col.add_field :internal_order_number
                    col.add_field :remarks
                    col.add_field :pricing_per_kg
                    col.add_field :pricing_per_carton
                  end
                end
              end
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Load',
                                  url: "/finished_goods/orders/orders/#{id}/create_load",
                                  visible: !ui_rule.form_object.allocated,
                                  style: :button)
              section.add_grid('loads',
                               "/list/loads/grid?key=order&order_id=#{id}",
                               caption: 'Loads',
                               height: 10)
            end
            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: ui_rule.form_object.step
              section.show_border!
              ui_rule.form_object.progress_controls.each do |control|
                section.add_control(control)
              end
            end
            page.form do |form|
              form.action '/list/orders'
              form.submit_captions 'Close'
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Order Item',
                                  url: "/finished_goods/orders/order_items/new?order_id=#{id}",
                                  visible: !ui_rule.form_object.allocated,
                                  behaviour: :popup,
                                  style: :button)
              section.add_grid('order_items',
                               "/finished_goods/orders/orders/#{id}/order_items_grid",
                               caption: 'Order Items',
                               height: 20)
            end
          end

          layout
        end
      end
    end
  end
end
