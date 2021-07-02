# frozen_string_literal: true

module Production
  module Runs
    module ProductResourceAllocation
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:product_resource_allocation, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Select Product Setup'
              form.action "/production/runs/product_resource_allocations/#{id}"
              form.method :update
              form.remote!
              form.add_field :product_setup_id
              form.add_field :packing_specification_item_id
              form.add_field :label_template_id
              form.add_field :packing_method_id
            end
          end

          layout
        end
      end
    end
  end
end
