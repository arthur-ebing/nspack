# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingRule
      class Show
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:grower_grading_rule, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Grower Grading Rule'
              form.view_only!
              form.row do |row|
                row.column do |col|
                  col.add_field :rule_name
                  col.add_field :file_name
                  col.add_field :packhouse_resource_id
                  col.add_field :line_resource_id
                  col.add_field :created_by
                  col.add_field :rebin_rule
                end
                row.column do |col|
                  col.add_field :description
                  col.add_field :cultivar_group_id
                  col.add_field :cultivar_id
                  col.add_field :season_id
                  col.add_field :updated_by
                  col.add_field :active
                end
              end
            end
          end
        end
      end
    end
  end
end
