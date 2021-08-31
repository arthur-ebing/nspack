# frozen_string_literal: true

module Masterfiles
  module Fruit
    module ColourPercentage
      class New
        def self.call(commodity_id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:colour_percentage, :new, commodity_id: commodity_id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Colour Percentage'
              form.action "/masterfiles/fruit/commodities/#{commodity_id}/colour_percentages"
              form.remote! if remote
              form.form_id 'colour_percentage_form'
              form.add_field :commodity_id
              form.add_field :commodity_code
              form.add_field :description
              form.add_field :colour_percentage

              form.add_notice('Use the close button of the dialog when finished.')
              form.submit_captions 'Add', 'Adding'
            end
          end
        end
      end
    end
  end
end
