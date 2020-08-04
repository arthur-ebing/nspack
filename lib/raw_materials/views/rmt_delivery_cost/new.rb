# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDeliveryCost
      class New
        def self.call(id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rmt_delivery_cost, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Rmt Delivery Cost'
              form.action "/raw_materials/deliveries/rmt_delivery_costs/#{id}/new"
              form.remote! if remote
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
