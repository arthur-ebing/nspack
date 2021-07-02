# frozen_string_literal: true

module Production
  module Reworks
    module ChangeDeliveriesOrchard
      class New
        def self.call(reworks_run_type_id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          ui_rule = UiRules::Compiler.new(:reworks_run, :new, form_values: form_values, reworks_run_type_id: reworks_run_type_id)
          rules   = ui_rule.compile

          if rules[:unscrap_pallet]
            grid = 'scrapped_pallets'
            grid_key = 'unscrap_reworks_pallets'
          elsif rules[:tip_bins] || rules[:tip_mixed_orchards]
            grid = 'rmt_bins_reworks'
            grid_key = 'tip_bins_reworks'
          else
            grid = 'stock_pallets'
            grid_key = 'reworks_pallets'
          end

          multi_select_caption = rules[:tip_bins] || rules[:tip_mixed_orchards] ? 'Bins' : 'Pallets'
          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'New Pallet Change'
              form.action "/production/reworks/reworks_run_types/#{reworks_run_type_id}/reworks_runs/new"
              form.remote! if remote
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :reworks_run_type
                  col.add_field :scrap_reason_id
                  col.add_field :remarks
                  col.add_field :pallets_selected
                end
                unless rules[:single_edit]
                  row.column do |col|
                    col.add_notice "Click button to select multiple reworks #{multi_select_caption}"
                    col.add_control(control_type: :link,
                                    text: "Select #{multi_select_caption}",
                                    url: "/list/#{grid}/multi?key=#{grid_key}&id=#{reworks_run_type_id}",
                                    behaviour: :popup,
                                    style: :button)
                  end
                end
              end
              form.row do |row|
                row.column do |col|
                  col.add_field :production_run_id
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
