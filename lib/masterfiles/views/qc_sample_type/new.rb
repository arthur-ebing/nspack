# frozen_string_literal: true

module Masterfiles
  module Quality
    module QcSampleType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:qc_sample_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Qc Sample Type'
              form.action '/masterfiles/quality/qc_sample_types'
              form.remote! if remote
              form.add_field :qc_sample_type_name
              form.add_field :description
              form.add_field :default_sample_size
              form.add_field :required_for_first_orchard_delivery
            end
          end
        end
      end
    end
  end
end
