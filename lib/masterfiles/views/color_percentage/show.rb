# frozen_string_literal: true

module Masterfiles
  module Fruit
    module ColorPercentage
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:color_percentage, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Color Percentage'
              form.view_only!
              form.add_field :commodity_id
              form.add_field :description
              form.add_field :color_percentage
              form.add_field :active
            end
          end
        end
      end
    end
  end
end
