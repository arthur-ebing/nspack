# frozen_string_literal: true

module Production
  module Runs
    module ProductionRun
      class BinTippingCriteria
        def self.call(id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_tipping_criteria, :new, production_run_id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.action "/production/runs/production_runs/#{id}/set_bin_tipping_criteria"
              form.remote! if remote
              form.add_field :toggle
              form.add_field :farm_code
              form.add_field :commodity_code
              form.add_field :rmt_variety_code
              form.add_field :treatment_code
              form.add_field :rmt_size
              form.add_field :product_class_code
              form.add_field :rmt_product_type
              form.add_field :pc_code
              form.add_field :cold_store_type
              form.add_field :season_code
              form.add_field :track_indicator_code
              form.add_field :ripe_point_code
            end
          end

          layout
        end
      end
    end
  end
end
