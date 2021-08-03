# frozen_string_literal: true

module Masterfiles
  module Parties
    module FruitIndustryLevy
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:fruit_industry_levy, :new, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Fruit Industry Levy'
              form.action '/masterfiles/parties/fruit_industry_levies'
              form.remote! if remote
              form.add_field :levy_code
              form.add_field :description
            end
          end
        end
      end
    end
  end
end
