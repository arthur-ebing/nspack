# frozen_string_literal: true

module Masterfiles
  module Quality
    module FruitDefect
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:fruit_defect, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Fruit Defect'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :defect_category
                  col.add_field :fruit_defect_code
                  col.add_field :short_description
                  col.add_field :internal
                  col.add_field :pre_harvest
                  col.add_field :qc_class_2
                  col.add_field :severity
                end
                row.column do |col|
                  col.add_field :fruit_defect_type_id
                  col.add_field :description
                  col.add_field :reporting_description
                  col.add_field :external
                  col.add_field :post_harvest
                  col.add_field :qc_class_3
                end
              end
            end
          end
        end
      end
    end
  end
end
