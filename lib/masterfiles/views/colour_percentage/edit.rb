# frozen_string_literal: true

module Masterfiles
  module Fruit
    module ColourPercentage
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:colour_percentage, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Colour Percentage'
              form.action "/masterfiles/fruit/colour_percentages/#{id}"
              form.remote!
              form.method :update
              form.add_field :commodity_id
              form.add_field :description
              form.add_field :colour_percentage
            end
          end
        end
      end
    end
  end
end
