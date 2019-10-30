# frozen_string_literal: true

module Masterfiles
  module Shipping
    module CargoTemperature
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:cargo_temperature, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Cargo Temperature'
              form.action "/masterfiles/shipping/cargo_temperatures/#{id}"
              form.remote!
              form.method :update
              form.add_field :temperature_code
              form.add_field :description
              form.add_field :set_point_temperature
              form.add_field :load_temperature
            end
          end

          layout
        end
      end
    end
  end
end
