# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class Show
        extend RawMaterialsApp::ViewHelpers::QC

        def self.call(id, back_url:) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :show, id: id)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)

              section.add_control(control_type: :link,
                                  text: 'Print Bin Barcodes',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/print_bin_barcodes",
                                  loading_window: true,
                                  style: :button)

              section.add_control(control_type: :link,
                                  text: 'Print Delivery',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/print_delivery",
                                  loading_window: true,
                                  style: :button)

              list_tripsheets = { text: 'List Tripsheets',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/list_tripsheet",
                                  behaviour: :popup,
                                  visible: rules[:list_tripsheets] }

              create_tripsheet = { text: 'Create Tripsheet',
                                   url: "/raw_materials/deliveries/rmt_deliveries/#{id}/create_tripsheet",
                                   behaviour: :popup,
                                   visible: rules[:create_tripsheet] }

              start_bins_trip = { text: 'Start Bins Trip',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/start_bins_trip",
                                  visible: rules[:start_bins_trip] }

              cancel_tripsheet = { text: 'Cancel Tripsheet',
                                   url: "/raw_materials/deliveries/rmt_deliveries/#{id}/cancel_delivery_tripheet",
                                   visible: rules[:cancel_delivery_tripheet] }
              cancel_tripsheet.store(:prompt, 'Vehicle is already loaded, do you want to cancel?') if rules[:vehicle_loaded]

              print_tripsheet = { text: 'Print Tripsheet',
                                  url: "/rmd/finished_goods/print_tripsheet/#{rules[:vehicle_job_id]}",
                                  visible: rules[:print_delivery_tripheet],
                                  loading_window: true }

              refresh_tripsheet = { text: 'Refresh Tripsheet',
                                    url: "/raw_materials/deliveries/rmt_deliveries/#{id}/refresh_delivery_tripheet",
                                    visible: rules[:refresh_tripsheet] }

              tripsheet_items = [create_tripsheet, start_bins_trip, list_tripsheets, cancel_tripsheet, print_tripsheet, refresh_tripsheet]
              section.add_control(control_type: :dropdown_button,
                                  text: 'Tripsheets',
                                  items: tripsheet_items,
                                  visible: rules[:tripsheet_button])

              section.add_notice rules[:mrl_result_notice], notice_type: :warning if AppConst::CR_RMT.enforce_mrl_check? && !rules[:mrl_result_notice].nil_or_empty?
              section.add_text rules[:compact_header]
              section.form do |form|
                form.view_only!
                form.no_submit!
              end
            end

            # QC Section from Helper
            qc_section(page, rules) if rules[:do_qc]

            if ui_rule.form_object.keep_open
              page.section do |section|
                bin_type = nil
                if ui_rule.form_object.bin_scan_mode == AppConst::AUTO_ALLOCATE_BIN_NUMBERS
                  section.add_control(control_type: :link,
                                      text: 'Create Bin Groups(Auto Allocate)',
                                      url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/create_bin_groups",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: :popup)
                  bin_type = 'asset_number_'
                elsif ui_rule.form_object.bin_scan_mode == AppConst::SCAN_BIN_GROUPS
                  section.add_control(control_type: :link,
                                      text: 'Scan Bin Groups',
                                      url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/create_scanned_bin_groups",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: :popup)
                  bin_type = 'asset_number_'
                elsif ui_rule.form_object.bin_scan_mode == AppConst::SCAN_BINS_INDIVIDUALLY
                  section.add_control(control_type: :link,
                                      text: 'New RMT Bin',
                                      url: "/rmd/rmt_deliveries/rmt_bins/#{id}/new_delivery_bin",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: false)
                  bin_type = 'asset_number_'
                else
                  section.add_control(control_type: :link,
                                      text: 'New RMT Bin',
                                      url: "/raw_materials/deliveries/rmt_deliveries/#{id}/rmt_bins/new",
                                      style: :button,
                                      grid_id: 'rmt_bins_deliveries',
                                      behaviour: :popup)
                end
                section.add_grid('rmt_bins_deliveries',
                                 "/list/#{bin_type}rmt_bins/grid?key=standard&delivery_id=#{id}",
                                 caption: 'Bins')
              end
            else
              page.section do |section|
                section.add_grid('rmt_bins_deliveries',
                                 "/list/rmt_bins_deliveries/grid?key=standard&delivery_id=#{id}",
                                 caption: 'Bins')
              end
            end
          end
        end
      end
    end
  end
end
