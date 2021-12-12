# frozen_string_literal: true

module Masterfiles
  module Quality
    module QcMeasurementType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:qc_measurement_type, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Qc Measurement Type'
              form.view_only!
              form.add_field :qc_measurement_type_name
              form.add_field :description
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
