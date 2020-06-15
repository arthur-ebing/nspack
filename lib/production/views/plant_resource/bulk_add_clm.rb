# frozen_string_literal: true

module Production
  module Resources
    module PlantResource
      class BulkAddClm
        def self.call(id: nil, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bulk_add_resource, :clm, parent_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/resources/plant_resources/#{id}/bulk_add/clm"
              form.remote! if remote
              form.add_field :no_clms
              form.add_field :no_clms_per_printer
              form.add_field :no_buttons
              form.add_field :plant_resource_prefix
              form.add_field :starting_no
            end
          end

          layout
        end
      end
    end
  end
end
