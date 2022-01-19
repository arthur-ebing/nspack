# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class New
        def self.call(reworks_run_type_id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          ui_rule = UiRules::Compiler.new(:reworks_run, :new, form_values: form_values, reworks_run_type_id: reworks_run_type_id)
          rules   = ui_rule.compile

          if rules[:unscrap_pallet]
            grid = 'scrapped_pallets'
            grid_key = 'unscrap_reworks_pallets'
          elsif rules[:tip_bins] || rules[:tip_mixed_orchards]
            grid = 'rmt_bins_reworks'
            grid_key = 'tip_bins_reworks'
          elsif rules[:untip_bins]
            grid = 'rmt_bins_reworks'
            grid_key = 'untip_bins_reworks'
          elsif rules[:bulk_weigh_bins]
            grid = 'rmt_bins_reworks'
            grid_key = 'bulk_weigh_bins'
          elsif rules[:scrap_bin]
            grid = 'rmt_bins_reworks'
            grid_key = 'scrap_bins_reworks'
          elsif rules[:unscrap_bin]
            grid = 'scrapped_rmt_bins_reworks'
            grid_key = 'unscrap_bins_reworks'
          elsif rules[:scrap_pallet]
            grid = 'stock_pallets'
            grid_key = 'scrap_reworks_pallets'
          elsif rules[:restore_repacked_pallet]
            grid = 'repacked_pallets'
            grid_key = 'restore_repacked_pallets'
          elsif rules[:scrap_carton]
            grid = 'reworks_cartons'
            grid_key = 'scrap_reworks_cartons'
          elsif rules[:unscrap_carton]
            grid = 'reworks_cartons'
            grid_key = 'unscrap_reworks_cartons'
          else
            grid = 'stock_pallets'
            grid_key = 'reworks_pallets'
          end

          multi_select_caption = if rules[:bin_run_type]
                                   'Bins'
                                 elsif rules[:carton_run_type]
                                   'Cartons'
                                 else
                                   'Pallets'
                                 end
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Reworks Run'
              form.action "/production/reworks/reworks_run_types/#{reworks_run_type_id}/reworks_runs/new"
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :reworks_run_type
                  col.add_field :scrap_reason_id
                  col.add_field :remarks
                  col.add_field :pallets_selected
                  col.add_field :bin_asset_number
                end
                if rules[:single_edit] || rules[:bulk_production_run_update]
                  row.blank_column
                else
                  row.column do |col|
                    col.add_notice "Click button to select multiple reworks #{multi_select_caption}"
                    col.add_control(id: 'reworks_run_select_button',
                                    control_type: :link,
                                    text: "Select #{multi_select_caption}",
                                    url: "/production/reworks/reworks_run_types/#{reworks_run_type_id}/reworks_runs/display_reworks_multiselect_grid/#{grid}/#{grid_key}",
                                    behaviour: :popup,
                                    style: :button)
                  end
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :production_run_id
                  col.add_field :allow_cultivar_group_mixing
                  col.add_field :allow_cultivar_mixing
                end
                row.blank_column
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :from_production_run_id
                  col.add_field :to_production_run_id
                  col.add_field :created_at
                  col.add_field :tipped
                end
                row.blank_column
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :gross_weight
                  col.add_field :avg_gross_weight
                end
                row.blank_column
              end
              if rules[:bulk_update_pallet_dates]
                form.row do |row|
                  row.column do |col|
                    col.add_field :first_cold_storage_at
                  end
                  row.blank_column
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
