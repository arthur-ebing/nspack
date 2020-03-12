# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class AddPallet
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :add_pallet, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.form do |form|
              form.caption 'Inspection Sheet'
              form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}/add_pallet"
              form.submit_captions 'Add Pallet'

              form.row do |row|
                row.column do |col|
                  col.add_field :inspector_id
                  col.add_field :inspection_billing_party_role_id
                  col.add_field :exporter_party_role_id
                  col.add_field :booking_reference
                  col.add_field :pallet_number
                end
                row.column do |col|
                  col.add_field :inspection_point
                  col.add_field :destination_country_id
                  col.add_field :completed
                  col.add_field :inspected
                end
              end
            end
            page.form do |form|
              form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}/complete"
              form.submit_captions 'Complete adding pallets'
            end
            page.section do |section|
              section.add_grid('govt_inspection_pallets',
                               "/list/govt_inspection_pallets/grid?key=standard&id=#{id}",
                               caption: 'Govt Inspection Pallets',
                               height: 40)
            end
          end

          layout
        end
      end
    end
  end
end
