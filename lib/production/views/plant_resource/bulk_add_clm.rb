# frozen_string_literal: true

module Production
  module Resources
    module PlantResource
      class BulkAddClm
        def self.call(id: nil, form_values: nil, form_errors: nil, remote: true)
          # ui_rule = UiRules::Compiler.new(:plant_resource, :new, parent_id: id, form_values: form_values)
          # rules   = ui_rule.compile
          rules = { name: 'resource',
                    fields: { no_clms: { renderer: :integer, required: true },
                              no_clms_per_printer: { renderer: :integer, required: true },
                              no_buttons: { renderer: :integer, required: true },
                              plant_resource_prefix: { required: true },
                              starting_no: {},
                              starting_sys_no: {} } }
          # default prefix to ph/line concat.
          # Use new UI rule: bulk_add_resource
          form_object = OpenStruct.new(no_clms: 2, no_buttons: 4, no_clms_per_printer: 1, plant_resource_prefix: 'CLM', starting_no: nil, starting_sys_no: nil)

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            # page.form_object ui_rule.form_object
            page.form_object form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              # form.caption 'New Plant Resource'
              form.action "/production/resources/plant_resources/#{id}/bulk_add/clm"
              form.remote! if remote
              form.add_field :no_clms
              form.add_field :no_clms_per_printer
              form.add_field :no_buttons
              form.add_field :plant_resource_prefix
              form.add_field :starting_no
              form.add_field :starting_sys_no
            end
          end

          layout
        end
      end
    end
  end
end
