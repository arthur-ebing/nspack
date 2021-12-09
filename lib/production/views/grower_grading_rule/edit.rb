# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingRule
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:grower_grading_rule, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Edit Grower Grading Rule'
              form.action "/production/grower_grading/grower_grading_rules/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :rule_name
                  col.add_field :packhouse_resource_id
                  col.add_field :line_resource_id
                  col.add_field :rebin_rule
                  col.add_field :created_by
                end
                row.column do |col|
                  col.add_field :description
                  col.add_field :cultivar_group_id
                  col.add_field :cultivar_id
                  col.add_field :season_id
                  col.add_field :updated_by
                end
              end
            end
          end
        end
      end
    end
  end
end
