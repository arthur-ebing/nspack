# frozen_string_literal: true

module Masterfiles
  module Quality
    module FruitDefectType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:fruit_defect_type, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Fruit Defect Type'
              form.view_only!
              form.add_field :fruit_defect_type_name
              form.add_field :description
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
