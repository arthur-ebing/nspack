# frozen_string_literal: true

module Production
  module Resources
    module PlantResourceType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:plant_resource_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.add_field :plant_resource_type_code
              form.add_field :description
              form.add_field :active
              form.add_field :packpoint
              form.add_text rules[:icon_render]
            end
          end

          layout
        end
      end
    end
  end
end
