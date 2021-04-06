# frozen_string_literal: true

module Production
  module Orders
    module WorkOrder
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true, marketing_order_id: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:work_order, :new, form_values: form_values, marketing_order_id: marketing_order_id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Work Order'
              form.action '/production/orders/work_orders'
              form.action "/production/orders/marketing_orders/#{marketing_order_id}/new_work_order" if marketing_order_id
              form.remote! if remote
              form.add_field :marketing_order_id
              form.add_field :start_date
              form.add_field :end_date
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
