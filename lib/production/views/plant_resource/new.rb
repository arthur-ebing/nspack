# frozen_string_literal: true

module Production
  module Resources
    module PlantResource
      class New
        def self.call(id: nil, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:plant_resource, :new, parent_id: id, form_values: form_values)
          rules   = ui_rule.compile

          action = id.nil? ? '/production/resources/plant_resources' : "/production/resources/plant_resources/#{id}/add_child"

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Plant Resource'
              form.action action
              form.remote! if remote
              form.add_field :plant_resource_type_id
              # form.add_field :system_resource_id
              form.add_field :plant_resource_code
              form.add_field :description
              # form.add_field :resource_attributes
            end
          end

          layout
        end
      end
    end
  end
end
