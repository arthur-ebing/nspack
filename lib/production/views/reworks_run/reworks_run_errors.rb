# frozen_string_literal: true

module Production
  module Runs
    module ReworksRun
      class ReworksRunErrors
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:bulk_tip_bin_process, nil)
          rules   = ui_rule.compile
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object

            page.section do |section|
              section.add_grid('reworks_run_errors',
                               "/production/reworks/reworks_run_errors_grid/#{id}",
                               caption: 'Reworks Run Errors')
            end
          end
          layout
        end
      end
    end
  end
end
