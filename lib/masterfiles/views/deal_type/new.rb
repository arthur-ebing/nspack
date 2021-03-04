# frozen_string_literal: true

module Masterfiles
  module Finance
    module DealType
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:deal_type, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Deal Type'
              form.action '/masterfiles/finance/deal_types'
              form.remote! if remote
              form.add_field :deal_type
              form.add_field :fixed_amount
            end
          end

          layout
        end
      end
    end
  end
end
