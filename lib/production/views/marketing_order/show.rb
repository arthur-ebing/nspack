# frozen_string_literal: true

module Production
  module Orders
    module MarketingOrder
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:marketing_order, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Marketing Order'
              form.view_only!
              form.add_field :customer_party_role_id
              form.add_field :season_id
              form.add_field :order_number
              form.add_field :order_reference
              form.add_field :carton_qty_required
              form.add_field :carton_qty_produced
              form.add_field :completed
              form.add_field :completed_at
            end
          end

          layout
        end
      end
    end
  end
end
