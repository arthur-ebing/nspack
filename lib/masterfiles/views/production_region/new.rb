# frozen_string_literal: true

module Masterfiles
  module Farms
    module ProductionRegion
      class New
        def self.call(form_values: nil, form_errors: nil, remote: true)
          ui_rule = UiRules::Compiler.new(:production_region, :new, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Production Region'
              form.action '/masterfiles/farms/production_regions'
              form.remote! if remote
              form.add_field :production_region_code
              form.add_field :description
              form.add_field :inspection_region
            end
          end

          layout
        end
      end
    end
  end
end
