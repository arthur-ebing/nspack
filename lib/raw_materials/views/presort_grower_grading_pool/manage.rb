# frozen_string_literal: true

module RawMaterials
  module PresortGrowerGrading
    module PresortGrowerGradingPool
      class Manage
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:presort_grower_grading_pool, :manage, id: id)
          rules   = ui_rule.compile

          grid = rules[:completed] ? 'presort_grower_grading_bins_show' : 'presort_grower_grading_bins'
          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/presort_grower_grading_pools',
                                  style: :back_button)
            end
            page.section do |section|
              section.form do |form|
                form.view_only!
                form.no_submit!
                form.row do |row|
                  row.column do |col|
                    col.add_text rules[:compact_header]
                  end
                  row.column do |col|
                    col.add_field :rmt_bin_weight
                    col.add_field :total_graded_weight
                    col.add_field :input_minus_output_weight
                  end
                end
              end
            end
            page.section do |section|
              section.show_border!
              section.add_control(control_type: :link,
                                  text: 'New Grading Bin',
                                  url: "/raw_materials/presort_grower_grading/presort_grower_grading_pools/#{id}/presort_grower_grading_bins/new",
                                  style: :button,
                                  behaviour: :popup)
              section.add_grid('grower_grading_bins',
                               "/list/#{grid}/grid?key=standard&presort_grower_grading_pool_id=#{id}",
                               caption: 'Presort Grading Bins')
            end
          end
        end
      end
    end
  end
end
