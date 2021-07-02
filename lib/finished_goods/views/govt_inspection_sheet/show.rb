# frozen_string_literal: true

module FinishedGoods
  module Inspection
    module GovtInspectionSheet
      class Show
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          ui_rule = UiRules::Compiler.new(:govt_inspection_sheet, :show, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/govt_inspection_sheets',
                                  style: :back_button)
              unless ui_rule.form_object.cancelled
                ui_rule.form_object.instance_controls.each do |control|
                  section.add_control(control)
                end
                section.add_control(control_type: :link,
                                    text: 'Print Passed Inspection Report',
                                    url: "/finished_goods/reports/passed_inspection_report/#{id}",
                                    visible: ui_rule.form_object.passed_pallets,
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Print Failed Inspection Report',
                                    url: "/finished_goods/reports/failed_inspection_report/#{id}",
                                    visible: ui_rule.form_object.failed_pallets,
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Print Finding Sheet',
                                    url: "/finished_goods/reports/finding_sheet/#{id}",
                                    visible: ui_rule.form_object.allocated,
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
            end
            page.form do |form|
              # form.caption 'Govt Inspection Sheet'
              form.submit_captions 'Add Pallet'
              if AppConst::CONTINUOUS_GOVT_INSPECTION_SHEETS
                form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}/add_inspected_pallet"
                form.remote!
              else
                form.action "/finished_goods/inspection/govt_inspection_sheets/#{id}/add_pallet"
              end
              form.no_submit! if ui_rule.form_object.completed
              form.fold_up do |fold|
                fold.caption 'Govt Inspection Sheet'
                fold.row do |row|
                  row.column do |col|
                    col.add_field :inspector
                    col.add_field :inspection_billing
                    col.add_field :exporter
                    col.add_field :booking_reference
                    col.add_field :created_by
                    col.add_field :upn
                    col.add_field :status
                  end
                  row.column do |col|
                    col.add_field :consignment_note_number
                    col.add_field :inspection_point
                    # col.add_field :packed_tm_group
                    col.add_field :destination_region
                    col.add_field :destination_country
                    col.add_field :use_inspection_destination_for_load_out
                    col.add_field :completed
                    col.add_field :inspected
                    col.add_field :reinspection
                  end
                end
              end
              form.add_field :scanned_number
            end
            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: ui_rule.form_object.step
              section.show_border!
              unless ui_rule.form_object.cancelled
                ui_rule.form_object.progress_controls.each do |control|
                  section.add_control(control)
                end
              end
            end
            page.form do |form|
              form.action '/list/govt_inspection_sheets'
              form.submit_captions 'Close'
            end
            page.section do |section|
              if ui_rule.form_object.step == 1
                section.add_grid('govt_inspection_pallets',
                                 '/list/govt_inspection_pallets/grid_multi',
                                 caption: 'Choose pallets that passed inspection.',
                                 is_multiselect: true,
                                 multiselect_url: '/finished_goods/inspection/govt_inspection_pallets/capture',
                                 multiselect_key: 'standard',
                                 multiselect_params: { key: 'standard', id: id },
                                 height: 40)
              else
                section.add_grid('govt_inspection_pallets',
                                 "/list/govt_inspection_pallets/grid?key=standard&id=#{id}",
                                 caption: 'Govt Inspection Pallets',
                                 height: 40)
              end
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable
