# frozen_string_literal: true

module Masterfiles
  module Shipping
    module VehicleType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:vehicle_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Vehicle Type'
              form.action "/masterfiles/shipping/vehicle_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :vehicle_type_code
              form.add_field :description
              form.add_field :has_container
            end
          end

          layout
        end
      end
    end
  end
end
