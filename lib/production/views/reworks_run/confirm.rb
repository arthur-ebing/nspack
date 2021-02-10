# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class Confirm
        def self.call(remote: true)
          rules = { name: 'reworks' }

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form do |form|
              form.no_submit!
              form.remote! if remote
              form.add_text "Are you sure you want to re-calculate all bins nett_weight? <br> Press 'Yes' to recalculate."
            end

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Yes',
                                  url: '/production/reworks/reworks_run_types/recalc_bin_nett_weight/reworks_runs/recalc_bins_nett_weight',
                                  visible: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'No',
                                  url: '/production/reworks/reworks_run_types/recalc_bin_nett_weight/reworks_runs/cancel_recalc',
                                  visible: true,
                                  style: :button)
            end
          end

          layout
        end
      end
    end
  end
end
