# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtClassificationType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rmt_classification_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Rmt Classification Type'
              form.action '/masterfiles/raw_materials/rmt_classification_types'
              form.remote! if remote
              form.add_field :rmt_classification_type_code
              form.add_field :description
              form.add_field :required_for_delivery
              form.add_field :physical_attribute
            end
          end
        end
      end
    end
  end
end
