# frozen_string_literal: true

module Masterfiles
  module Quality
    module QcSampleType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:qc_sample_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Qc Sample Type'
              form.action "/masterfiles/quality/qc_sample_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :qc_sample_type_name
              form.add_field :description
              form.add_field :default_sample_size
            end
          end
        end
      end
    end
  end
end
