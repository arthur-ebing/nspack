# frozen_string_literal: true

module Masterfiles
  module Parties
    module FruitIndustryLevy
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:fruit_industry_levy, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Fruit Industry Levy'
              form.view_only!
              form.add_field :levy_code
              form.add_field :description
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
