# frozen_string_literal: true

module Production
  module Reports
    module Packout
      class SearchProductionRuns
        def self.call(mode: :packout)
          ui_rule = UiRules::Compiler.new(:packout_runs_report, mode)
          rules   = ui_rule.compile
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Packout Runs Report'
              form.action mode == :packout ? '/production/reports/packout_runs' : '/production/runs/production_runs/search'
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :orchard_id
              form.add_field :cultivar_group_id
              form.add_field :cultivar_id
              form.add_field :packhouse_resource_id
              form.add_field :production_line_id
              form.add_field :season_id
              form.add_field :dispatches_only if mode == :packout
              form.add_field :use_derived_weight if mode == :packout
            end
          end
          layout
        end
      end
    end
  end
end
