# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:production_run, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form| # rubocop:disable Metrics/BlockLength
              form.caption 'Edit Production Run'
              form.action "/production/runs/production_runs/#{id}"
              form.remote!
              form.method :update
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :packhouse_resource_id
              form.add_field :production_line_id
              form.add_field :season_id
              form.add_field :orchard_id
              form.add_field :cultivar_group_id
              form.add_field :cultivar_id
              form.add_field :product_setup_template_id
              form.add_field :cloned_from_run_id
              form.add_field :active_run_stage
              form.add_field :started_at
              form.add_field :closed_at
              form.add_field :re_executed_at
              form.add_field :completed_at
              form.add_field :allow_cultivar_mixing
              form.add_field :allow_orchard_mixing
              form.add_field :reconfiguring
              form.add_field :running
              form.add_field :closed
              form.add_field :setup_complete
              form.add_field :completed
            end
          end

          layout
        end
      end
    end
  end
end
