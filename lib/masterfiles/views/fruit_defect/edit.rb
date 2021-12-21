# frozen_string_literal: true

module Masterfiles
  module Quality
    module FruitDefect
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:fruit_defect, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Fruit Defect'
              form.action "/masterfiles/quality/fruit_defects/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :defect_category
                  col.add_field :fruit_defect_type_id
                  col.add_field :fruit_defect_code
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :short_description
                  col.add_field :internal
                  col.add_field :pre_harvest
                  col.add_field :qc_class_2
                  col.add_field :severity
                end
                row.column do |col|
                  col.add_field :reporting_description
                  col.add_field :external
                  col.add_field :post_harvest
                  col.add_field :qc_class_3
                  col.add_field :description
                end
              end
            end
          end
        end
      end
    end
  end
end
