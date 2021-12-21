# frozen_string_literal: true

module Quality
  module Qc
    module QcTest
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:qc_test, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Qc Test'
              form.action "/quality/qc/qc_tests/#{id}"
              form.remote!
              form.method :update
              form.add_field :qc_measurement_type_id
              form.add_field :qc_sample_id
              form.add_field :qc_test_type_id
              form.add_field :instrument_plant_resource_id
              form.add_field :sample_size
              form.add_field :editing
              form.add_field :completed
              form.add_field :completed_at
            end
          end
        end
      end
    end
  end
end
