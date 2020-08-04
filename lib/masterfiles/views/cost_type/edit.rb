# frozen_string_literal: true

module Masterfiles
  module Costs
    module CostType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:cost_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Cost Type'
              form.action "/masterfiles/costs/cost_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :cost_type_code
              form.add_field :cost_unit
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
