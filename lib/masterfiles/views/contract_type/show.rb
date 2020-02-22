# frozen_string_literal: true

module Masterfiles
  module HumanResources
    module ContractType
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:contract_type, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Contract Type'
              form.view_only!
              form.add_field :contract_type_code
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
