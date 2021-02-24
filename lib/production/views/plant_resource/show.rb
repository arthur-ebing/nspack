# frozen_string_literal: true

module Production
  module Resources
    module PlantResource
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:plant_resource, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :plant_resource_type_id
              form.add_field :plant_resource_code
              form.add_field :description
              form.add_field :system_resource_code if ui_rule.form_object.system_resource_code
              form.add_field :represents_plant_resource_code
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
