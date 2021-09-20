# frozen_string_literal: true

module Masterfiles
  module TargetMarkets
    module TargetMarket
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:target_market, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action '/masterfiles/target_markets/target_markets'
              form.remote! if remote
              form.add_field :target_market_name
              form.add_field :tm_group_ids
              form.add_field :country_ids
              form.add_field :target_customer_ids
              form.add_field :description
              form.add_field :inspection_tm
            end
          end

          layout
        end
      end
    end
  end
end
