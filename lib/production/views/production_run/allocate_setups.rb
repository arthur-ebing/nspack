# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class AllocateSetups
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :allocate_setups, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            # page.add_text '<a href="/help/app/production/allocate_setups" target="cbf-help">? HELP</a>'
            # page.add_help_link url: '/help/app/production/allocate_setups', text: 'Help'
            page.add_help_link path: %i[production allocate_setups]
            page.add_text 'Allocate setups', wrapper: :h2
            page.add_text rules[:compact_header]
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/production_runs',
                                  style: :back_button)
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('production_run_allocated_setups',
                               "/list/production_run_allocated_setups/grid?key=standard&production_run_id=#{id}",
                               caption: "Allocate Setups for production run #{ui_rule.form_object.production_run_code}")
            end
            # show grid
            # page.form do |form|
            #   form.caption 'Allocate setups to Production Run'
            #   form.action "/production/runs/production_runs/#{id}"
            #   form.remote!
            #   form.method :update
            #   form.add_field :farm_id
            # end
          end

          layout
        end
      end
    end
  end
end
