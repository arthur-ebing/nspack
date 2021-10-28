# frozen_string_literal: true

module RawMaterials
  module Locations
    module Location
      class ApplyStatus
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:rmt_location, :apply_status, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Location'
              form.action "/raw_materials/locations/ca_treatment/#{id}/apply_status"
              form.remote!
              form.add_field :location_long_code
              form.add_field :current_status
              form.add_field :status
            end
          end
        end
      end
    end
  end
end
