# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class CompleteStage
        def self.call(id, res, complete_run: false) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :complete_stage, id: id, complete_run: complete_run)
          rules   = ui_rule.compile
          url_suffix = complete_run ? 'run' : 'stage'

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.add_text rules[:compact_header]
            page.form do |form|
              form.caption 'Complete stage'
              form.action "/production/runs/production_runs/#{id}/complete_#{url_suffix}"
              form.remote!
              if res.success
                form.add_notice res.message, show_caption: false
                form.add_field :current_stage
                form.add_field :new_stage
                form.submit_captions 'Complete', 'Completing...'
              else
                form.add_notice res.message, notice_type: :error, inline_caption: true
                form.add_field :current_stage
                form.no_submit!
              end
            end
          end

          layout
        end
      end
    end
  end
end
