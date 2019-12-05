# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class New
        def self.call(reworks_run_type_id, form_values: nil, form_errors: nil, remote: true) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run, :new, form_values: form_values, reworks_run_type_id: reworks_run_type_id)
          rules   = ui_rule.compile

          if rules[:unscrap_pallet]
            grid = 'scrapped_pallets'
            grid_key = 'unscrap_reworks_pallets'
          else
            grid = 'stock_pallets'
            grid_key = 'reworks_pallets'
          end

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
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
                unless rules[:single_pallet_edit]
                  row.column do |col|
                    col.add_notice 'Click button to select multiple reworks pallets'
                    col.add_control(control_type: :link,
                                    text: 'Select Pallets',
                                    url: "/list/#{grid}/multi?key=#{grid_key}&id=#{reworks_run_type_id}",
                                    behaviour: :popup,
                                    style: :button)
                  end
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
