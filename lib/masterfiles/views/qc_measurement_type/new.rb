# frozen_string_literal: true

module Masterfiles
  module Quality
    module QcMeasurementType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:qc_measurement_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Qc Measurement Type'
              form.action '/masterfiles/quality/qc_measurement_types'
              form.remote! if remote
              form.add_field :qc_measurement_type_name
              form.add_field :description
            end
          end
        end
      end
    end
  end
end
