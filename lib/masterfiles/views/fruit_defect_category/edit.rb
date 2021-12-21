# frozen_string_literal: true

module Masterfiles
  module Quality
    module FruitDefectCategory
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:fruit_defect_category, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Fruit Defect Category'
              form.action "/masterfiles/quality/fruit_defect_categories/#{id}"
              form.remote!
              form.method :update
              form.add_field :defect_category
              form.add_field :reporting_description
            end
          end
        end
      end
    end
  end
end
