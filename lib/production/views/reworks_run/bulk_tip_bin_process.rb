# frozen_string_literal: true

module Production
  module Runs
    module ReworksRun
      class BulkTipBinProcess
        def self.call(step, params = nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bulk_tip_bin_process, nil)
          rules   = ui_rule.compile
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object

            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: step, show_finished: true
              # section.show_border!
            end

            page.section do |section|
              case step
              when 0
                section.add_grid('select_bins',
                                 '/list/untipped_bins/grid_multi',
                                 caption: 'Select Bins',
                                 is_multiselect: true,
                                 can_be_cleared: false,
                                 multiselect_url: '/production/reworks/selected_untipped_bins',
                                 multiselect_key: 'standard',
                                 height: 40,
                                 multiselect_params: params)
              when 1
                section.add_grid('bulk_tip_bins',
                                 '/production/reworks/suggested_runs_multiselect',
                                 caption: 'Bulk Tip Bins',
                                 is_multiselect: true,
                                 can_be_cleared: false,
                                 multiselect_url: '/production/reworks/bulk_tip_bins',
                                 height: 40,
                                 multiselect_key: 'standard',
                                 multiselect_params: {})
              when 2
                section.add_control(control_type: :link,
                                    text: 'Next',
                                    url: '/production/reworks/view_summary',
                                    style: :action_button)

                section.add_grid('edit_suggested_runs',
                                 '/production/reworks/edit_suggested_runs',
                                 caption: 'Edit Sugested Runs',
                                 height: 40)
              when 3
                section.add_control(control_type: :link,
                                    text: 'Back',
                                    url: '/production/reworks/back_to_editing_runs',
                                    style: :back_button)
                section.add_control(control_type: :link,
                                    text: 'Finish',
                                    url: '/production/reworks/finish',
                                    style: :action_button)

                section.add_grid('summary',
                                 '/production/reworks/summary',
                                 caption: 'Bulk/Individually Tipped Bins',
                                 height: 40)
              end
            end
          end
          layout
        end
      end
    end
  end
end
