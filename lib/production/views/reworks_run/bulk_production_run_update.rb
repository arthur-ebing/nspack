# frozen_string_literal: true

module Production
  module Reworks
    module ReworksRun
      class BulkProductionRunUpdate
        def self.call(id, attrs)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:reworks_run_bulk_update, :production_run_bulk_update, id: id, attrs: attrs)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form do |form|
              form.view_only!
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :reworks_run_type_id
                  col.add_field :reworks_run_type
                  col.add_field :from_production_run_id
                  col.add_field :to_production_run_id
                end
              end
            end
            page.section do |section|
              section.add_notice 'The following production run details has changed'
              section.add_diff :changes_made
            end
            page.add_notice 'Select pallets for update from the grid below'
            page.section do |section|
              section.fit_height!
              section.add_grid('stock_pallets',
                               '/list/stock_pallets/grid_multi',
                               caption: 'Choose Pallets',
                               is_multiselect: true,
                               can_be_cleared: false,
                               multiselect_url: "/production/reworks/reworks_run_types/#{id}/reworks_runs/multiselect_reworks_run_bulk_production_run_update",
                               multiselect_key: 'reworks_bulk_update_pallets',
                               multiselect_params: { key: 'reworks_bulk_update_pallets',
                                                     id: id,
                                                     production_run_id: attrs[:from_production_run_id] })
            end
            page.section do |section|
              section.row do |row|
                row.column do |col|
                  col.add_control(control_type: :link,
                                  text: 'Reject Changes',
                                  url: "/production/reworks/reworks_run_types/#{id}/reject_bulk_production_run_update",
                                  style: :button)
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
