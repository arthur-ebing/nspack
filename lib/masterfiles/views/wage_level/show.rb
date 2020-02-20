# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module WageLevel
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:wage_level, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Wage Level'
              form.view_only!
              form.add_field :wage_level
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
