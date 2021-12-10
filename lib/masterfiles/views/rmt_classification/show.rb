# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtClassification
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_classification, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Rmt Classification'
              form.view_only!
              form.add_field :rmt_classification_type_id
              form.add_field :rmt_classification
            end
          end
        end
      end
    end
  end
end
