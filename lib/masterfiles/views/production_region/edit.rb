# frozen_string_literal: true

module Masterfiles
  module Farms
    module ProductionRegion
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:production_region, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Production Region'
              form.action "/masterfiles/farms/production_regions/#{id}"
              form.remote!
              form.method :update
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
