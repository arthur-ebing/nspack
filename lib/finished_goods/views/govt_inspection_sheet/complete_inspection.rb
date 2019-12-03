# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class CompleteInspection
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :complete_inspection, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors

            page.form do |form|
              form.caption 'Inspection Sheet'
              form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}/complete_inspection"
              form.submit_captions 'Complete Inspection'
              form.row do |row|
                row.column do |col|
                  col.add_field :inspector_id
                  col.add_field :inspection_billing_party_role_id
                  col.add_field :exporter_party_role_id
                  col.add_field :booking_reference
                end
                row.column do |col|
                  col.add_field :inspection_point
                  col.add_field :destination_country_id
                  col.add_field :completed
                  col.add_field :inspected
                end
              end
            end
            page.add_notice 'Record inspection results'
            page.section do |section|
              section.fit_height!
              section.add_grid('govt_inspection_pallets',
                               '/list/govt_inspection_pallets/grid_multi',
                               caption: 'Inspect Pallets',
                               is_multiselect: true,
                               # can_be_cleared: true,
                               multiselect_url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/capture_results_multiselect",
                               multiselect_key: 'standard',
                               multiselect_params: { key: 'standard',
                                                     id: id })
            end
          end

          layout
        end
      end
    end
  end
end
