# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDeliveryCost
      class Show
        def self.call(rmt_delivery_id, cost_id)
          ui_rule = UiRules::Compiler.new(:rmt_delivery_cost, :show, rmt_delivery_id: rmt_delivery_id, cost_id: cost_id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Rmt Delivery Cost'
              form.view_only!
              form.add_field :cost_id
              form.add_field :amount
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
