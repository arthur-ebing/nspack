# frozen_string_literal: true

module Production
  module Reports
    module Packout
      class SearchPackoutRuns
        def self.call # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:packout_runs_report, :edit)
          rules   = ui_rule.compile
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              form.caption 'Packout Runs Report'
              form.action '/production/reports/packout_runs'
              form.add_field :farm_id
              form.add_field :puc_id
              form.add_field :orchard_id
              form.add_field :cultivar_group_id
              form.add_field :cultivar_id
              form.add_field :packhouse_resource_id
              form.add_field :production_line_id
              form.add_field :season_id
              form.add_field :dispatches_only
              form.add_field :use_derived_weight
            end
          end
          layout
        end
      end
    end
  end
end
