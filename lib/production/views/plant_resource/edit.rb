# frozen_string_literal: true

module Production
  module Resources
    module PlantResource
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:plant_resource, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Plant Resource'
              form.action "/production/resources/plant_resources/#{id}"
              form.remote!
              form.method :update
              form.add_field :plant_resource_type_id
              # form.add_field :system_resource_id
              form.add_field :plant_resource_code
              form.add_field :description
              form.add_field :location_id
              form.add_field :gln
              form.add_field :phc
              form.add_field :packhouse_no
            end
          end

          layout
        end
      end
    end
  end
end
