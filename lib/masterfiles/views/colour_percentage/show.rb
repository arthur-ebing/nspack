# frozen_string_literal: true

module Masterfiles
  module Fruit
    module ColourPercentage
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:colour_percentage, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Colour Percentage'
              form.view_only!
              form.add_field :commodity_id
              form.add_field :description
              form.add_field :colour_percentage
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
