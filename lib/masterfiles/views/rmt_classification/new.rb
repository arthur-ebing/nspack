# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtClassification
      class New
        def self.call(rmt_classification_type_id, form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:rmt_classification, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Rmt Classification'
              form.action "/masterfiles/raw_materials/rmt_classification_types/#{rmt_classification_type_id}/rmt_classifications"
              form.remote! if remote
              form.add_field :rmt_classification
            end
          end
        end
      end
    end
  end
end
