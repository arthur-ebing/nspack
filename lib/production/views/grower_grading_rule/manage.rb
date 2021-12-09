# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingRule
      class Manage
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:grower_grading_rule, :manage, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/grower_grading_rules',
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Rule Item',
                                  url: "/production/grower_grading/grower_grading_rules/#{id}/grower_grading_rule_items/new",
                                  style: :button,
                                  behaviour: :popup)
              section.add_grid('grower_grading_rule_items',
                               "/list/grower_grading_rule_items/grid?key=standard&grower_grading_rule_id=#{id}",
                               caption: 'Rule Items')
            end
          end

          layout
        end
      end
    end
  end
end
