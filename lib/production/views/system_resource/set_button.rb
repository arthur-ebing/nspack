# frozen_string_literal: true

module Production
  module Resources
    module SystemResource
      class SetButton
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:system_resource, :set_button, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit System Resource'
              form.action "/production/resources/system_resources/#{id}/set_button"
              form.remote!
              form.add_field :plant_resource_type_id
              form.add_field :system_resource_code
              form.add_field :description
              form.add_field :no_of_labels_to_print
            end
          end
        end
      end
    end
  end
end
