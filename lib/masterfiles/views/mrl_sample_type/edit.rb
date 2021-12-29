# frozen_string_literal: true

module Masterfiles
  module Quality
    module MrlSampleType
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:mrl_sample_type, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Mrl Sample Type'
              form.action "/masterfiles/quality/mrl_sample_types/#{id}"
              form.remote!
              form.method :update
              form.add_field :sample_type_code
              form.add_field :description
            end
          end
        end
      end
    end
  end
end
