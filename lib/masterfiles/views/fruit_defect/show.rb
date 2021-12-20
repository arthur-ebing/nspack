# frozen_string_literal: true

module Masterfiles
  module Quality
    module FruitDefect
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:fruit_defect, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Fruit Defect'
              form.view_only!
              form.add_field :rmt_class_id
              form.add_field :fruit_defect_type_id
              form.add_field :fruit_defect_code
              form.add_field :short_description
              form.add_field :description
              form.add_field :internal
            end
          end
        end
      end
    end
  end
end
