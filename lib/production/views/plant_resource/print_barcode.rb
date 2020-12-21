# frozen_string_literal: true

module Production
  module Resources
    module PlantResource
      class PrintBarcode
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:plant_resource, :print_barcode, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/resources/plant_resources/#{id}/print_barcode"
              form.remote!
              form.method :update
              form.add_field :plant_resource_code
              form.add_field :printer
              form.add_field :no_of_prints
            end
          end

          layout
        end
      end
    end
  end
end
