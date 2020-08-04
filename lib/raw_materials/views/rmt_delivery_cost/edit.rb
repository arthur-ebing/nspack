# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDeliveryCost
      class Edit
        def self.call(rmt_delivery_id, cost_id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:rmt_delivery_cost, :edit, rmt_delivery_id: rmt_delivery_id, cost_id: cost_id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Rmt Delivery Cost'
              form.action "/raw_materials/deliveries/rmt_delivery_costs/#{rmt_delivery_id}/update/#{cost_id}"
              form.remote!
              form.method :update
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
