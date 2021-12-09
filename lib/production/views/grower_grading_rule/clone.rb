# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingRule
      class Clone
        def self.call(id, form_values: nil, form_errors: nil)
          ui_rule = UiRules::Compiler.new(:grower_grading_rule, :clone, id: id, form_values: form_values)
          rules   = ui_rule.compile

          cloned_from = ProductionApp::GrowerGradingRepo.new.find_grower_grading_rule(id)&.rule_name
          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/grower_grading_rules',
                                  style: :back_button)
              section.add_text("Cloned from Grower Grading Rule: #{cloned_from}", wrapper: :h3)
            end
            page.form do |form|
              form.caption 'Clone Grower Grading Rule'
              form.action "/production/grower_grading/grower_grading_rules/#{id}/clone_grower_grading_rule"
              form.remote!
              form.row do |row|
                row.column do |col|
                  col.add_field :id
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

            page.section do |section|
              section.add_grid('grower_grading_rule_items',
                               "/list/grower_grading_rule_items_view/grid?key=standard&grower_grading_rule_id=#{id}",
                               caption: 'Rule Items')
            end
          end
        end
      end
    end
  end
end
