# frozen_string_literal: true

module Production
  module GrowerGrading
    module GrowerGradingPool
      class Manage
        def self.call(id, object_name)
          ui_rule = UiRules::Compiler.new(:grower_grading_pool, :manage, id: id, object_name: object_name)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/grower_grading_pools',
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.section do |section|
              section.show_border!
              if rules[:completed]
                section.add_grid("grower_grading_#{object_name}",
                                 "/list/grower_grading_#{object_name}_show/grid?key=standard&grower_grading_pool_id=#{id}",
                                 caption: object_name)
              else
                section.add_control(control_type: :link,
                                    text: "Complete #{object_name} grading",
                                    url: "/production/grower_grading/grower_grading_pools/#{id}/complete_objects_grading/#{object_name}",
                                    behaviour: false,
                                    style: :button,
                                    visible: rules[:complete_grading] && !rules[:reopen_grading])
                section.add_control(control_type: :link,
                                    text: "Re-Open #{object_name} grading",
                                    url: "/production/grower_grading/grower_grading_pools/#{id}/reopen_objects_grading/#{object_name}",
                                    behaviour: false,
                                    style: :button,
                                    visible: rules[:reopen_grading])
                section.add_grid("grower_grading_#{object_name}",
                                 "/list/grower_grading_#{object_name}/grid?key=standard&grower_grading_pool_id=#{id}",
                                 caption: object_name)
              end
            end
          end
        end
      end
    end
  end
end
