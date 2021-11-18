# frozen_string_literal: true

module Masterfiles
  module Farms
    module ProductionRegion
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:production_region, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Production Region'
              form.view_only!
              form.add_field :production_region_code
              form.add_field :description
              form.add_field :inspection_region
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
