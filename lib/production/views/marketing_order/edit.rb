# frozen_string_literal: true

module Production
  module Orders
    module MarketingOrder
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:marketing_order, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.form do |form|
                form.caption 'Edit Marketing Order'
                form.action "/production/orders/marketing_orders/#{id}"
                form.method :update
                form.add_field :customer_party_role_id
                form.add_field :season_id
                form.add_field :order_number
                form.add_field :order_reference
                form.add_field :carton_qty_required
                form.add_field :carton_qty_produced
                form.add_field :completed
                form.add_field :completed_at
                form.no_submit! if rules[:completed]
              end

              section.add_grid('work_orders',
                               "/list/work_orders/grid?key=standard&marketing_order_id=#{id}",
                               caption: 'Work Orders')
            end
          end

          layout
        end
      end
    end
  end
end
