# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class ExecuteRun
        def self.call(id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :execute_run, form_values: form_values, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Execute run'
              form.action "/production/runs/production_runs/#{id}/execute_run"
              form.remote! if remote
              form.add_notice 'Press the button to start tipping the run', show_caption: false
              form.submit_captions 'Execute', 'Executing...'
            end
          end

          layout
        end
      end
    end
  end
end
