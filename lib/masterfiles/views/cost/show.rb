# frozen_string_literal: true

module Masterfiles
  module Costs
    module Cost
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:cost, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Cost'
              form.view_only!
              form.add_field :cost_type_id
              form.add_field :cost_code
              form.add_field :default_amount
              form.add_field :description
            end
          end

          layout
        end
      end
    end
  end
end
