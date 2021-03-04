# frozen_string_literal: true

module Masterfiles
  module Finance
    module DealType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:deal_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Deal Type'
              form.view_only!
              form.add_field :deal_type
              form.add_field :fixed_amount
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
