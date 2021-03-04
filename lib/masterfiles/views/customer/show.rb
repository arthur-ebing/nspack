# frozen_string_literal: true

module Masterfiles
  module Finance
    module Customer
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:customer, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Customer'
              form.view_only!
              form.add_field :customer
              form.add_field :default_currency
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
