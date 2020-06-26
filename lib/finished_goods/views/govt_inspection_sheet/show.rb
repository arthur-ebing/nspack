# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section| # rubocop:disable Metrics/BlockLength
              section.add_control(control_type: :link,
                                  text: 'Print Passed Inspection Report',
                                  url: "/finished_goods/reports/passed_inspection_report/#{id}",
                                  visible: rules[:inspected],
                                  loading_window: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Print Failed Inspection Report',
                                  url: "/finished_goods/reports/failed_inspection_report/#{id}",
                                  visible: rules[:inspected],
                                  loading_window: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Print Finding Sheet',
                                  url: "/finished_goods/reports/finding_sheet/#{id}",
                                  visible: rules[:pallets_allocated],
                                  loading_window: true,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Create Intake Tripsheet',
                                  url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/create_intake_tripsheet",
                                  visible: rules[:create_intake_tripsheet],
                                  behaviour: :popup,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Load Vehicle',
                                  url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/load_vehicle",
                                  visible: rules[:load_vehicle],
                                  style: :button)

              if rules[:vehicle_loaded]
                action = 'vehicle_loaded_cancel_confirm'
                popup = :popup
              else
                popup = false
                action = 'cancel_tripsheet'
              end

              refresh_tripsheet_action = rules[:tripsheet_complete] ? 'refresh_tripsheet' : 'refresh_tripsheet_confirmed'
              section.add_control(control_type: :link,
                                  text: 'Cancel Tripsheet',
                                  url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/#{action}",
                                  visible: rules[:cancel_tripsheet],
                                  behaviour: popup,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Refresh Tripsheet',
                                  url: "/finished_goods/inspection/govt_inspection_sheets/#{id}/#{refresh_tripsheet_action}",
                                  visible: rules[:refresh_tripsheet],
                                  behaviour: rules[:tripsheet_complete] ? :popup : false,
                                  style: :button)
              section.add_control(control_type: :link,
                                  text: 'Print Tripsheet',
                                  url: "/finished_goods/reports/print_tripsheet/#{id}",
                                  visible: rules[:print_tripsheet],
                                  loading_window: true,
                                  style: :button)
            end
            page.form do |form|
              form.caption 'Govt Inspection Sheet'
              form.action '/list/govt_inspection_sheets'
              form.submit_captions 'Close'
              form.row do |row|
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
                  # col.add_field :packed_tm_group_id
                  col.add_field :destination_region_id
                  col.add_field :completed
                  col.add_field :inspected
                  col.add_field :reinspection
                end
              end
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
