# frozen_string_literal: true

module Masterfiles
  module Shipping
    module CargoTemperature
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:cargo_temperature, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Cargo Temperature'
              form.view_only!
              form.add_field :temperature_code
              form.add_field :description
              form.add_field :set_point_temperature
              form.add_field :load_temperature
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
