# frozen_string_literal: true

module Masterfiles
  module RawMaterials
    module RmtClassificationType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:rmt_classification_type, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Rmt Classification Type'
              form.view_only!
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
