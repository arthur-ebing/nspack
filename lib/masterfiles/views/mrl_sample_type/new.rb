# frozen_string_literal: true

module Masterfiles
  module Quality
    module MrlSampleType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:mrl_sample_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Mrl Sample Type'
              form.action '/masterfiles/quality/mrl_sample_types'
              form.remote! if remote
              form.add_field :sample_type_code
              form.add_field :description
            end
          end
        end
      end
    end
  end
end
