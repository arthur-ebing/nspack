# frozen_string_literal: true

module Production
  module Resources
    module PlantResource
      class Move
        def self.call(id: nil, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:plant_resource, :move, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Move Plant Resource'
              form.action "/production/resources/plant_resources/#{id}/move_node"
              form.remote! if remote
              form.add_field :plant_resource_type_id
              form.add_field :plant_resource_code
              form.add_field :description
              form.add_field :destination_node
            end
          end
        end
      end
    end
  end
end
