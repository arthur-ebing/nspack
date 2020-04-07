# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class Capture
        def self.call(id, back_url, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :capture, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.form do |form|
              form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}/capture"
              form.submit_captions 'Finish Inspection'
              form.fold_up do |fold|
                fold.caption 'Inspection Sheet'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :inspector_id
                    col.add_field :inspection_billing_party_role_id
                    col.add_field :exporter_party_role_id
                    col.add_field :booking_reference
                    col.add_field :created_by
                  end
                  row.column do |col|
                    col.add_field :consignment_note_number
                    col.add_field :inspection_point
                    col.add_field :packed_tm_group_id
                    col.add_field :destination_region_id
                    col.add_field :completed
                    col.add_field :inspected
                    col.add_field :reinspection
                  end
                end
              end
            end
            page.add_notice 'Record inspection results'
            page.section do |section|
              section.add_grid('govt_inspection_pallets',
                               '/list/govt_inspection_pallets/grid_multi',
                               caption: 'Choose pallets that passed inspection.',
                               is_multiselect: true,
                               multiselect_url: '/finished_goods/inspection/govt_inspection_pallets/capture',
                               multiselect_key: 'standard',
                               multiselect_params: { key: 'standard', id: id },
                               height: 40)
            end
          end

          layout
        end
      end
    end
  end
end
