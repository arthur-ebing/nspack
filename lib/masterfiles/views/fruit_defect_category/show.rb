# frozen_string_literal: true

module Masterfiles
  module Quality
    module FruitDefectCategory
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:fruit_defect_category, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Fruit Defect Category'
              form.view_only!
              form.add_field :defect_category
              form.add_field :reporting_description
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
