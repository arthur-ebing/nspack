# frozen_string_literal: true

module Production
  module Orders
    module WorkOrder
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:work_order, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              if rules[:marketing_order_id]
                section.add_control(control_type: :link,
                                    text: 'Back',
                                    url: "/production/orders/marketing_orders/#{rules[:marketing_order_id]}/edit",
                                    style: :back_button)
              end

              section.form do |form|
                form.caption 'Edit Work Order'
                form.action "/production/orders/work_orders/#{id}"
                form.method :update
                form.add_field :marketing_order_id
                form.add_field :start_date
                form.add_field :end_date
                form.add_field :active
                form.add_field :completed
                form.add_field :completed_at
                form.no_submit! if rules[:completed]
              end

              section.add_control(control_type: :link,
                                  text: 'Manage Items',
                                  url: "/production/orders/work_orders/#{id}/manage_items",
                                  style: :button,
                                  grid_id: 'work_order_items',
                                  behaviour: :popup)

              section.add_grid('work_order_items',
                               "/list/work_order_items/grid?key=standard&work_order_id=#{id}",
                               caption: 'Work Order Items')
            end
          end

          layout
        end
      end
    end
  end
end
