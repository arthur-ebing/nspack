# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class CompleteSetup
        def self.call(id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :complete_setup, form_values: form_values, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Mark Setup as complete'
              form.action "/production/runs/production_runs/#{id}/complete_setup"
              form.remote! if remote
              form.add_notice 'Press the button to mark setups as complete', show_caption: false
              form.submit_captions 'Mark as Complete', 'Completing...'
            end
          end

          layout
        end
      end
    end
  end
end
