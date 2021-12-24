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

              section.add_control(control_type: :link,
                                  text: 'List Tripsheets',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/list_tripsheet",
                                  behaviour: :popup,
                                  visible: rules[:list_tripsheets],
                                  style: :button)

              section.add_control(control_type: :link,
                                  text: 'Create Tripsheet',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/create_tripsheet",
                                  behaviour: :popup,
                                  visible: rules[:create_tripsheet],
                                  style: :button)

              section.add_control(control_type: :link,
                                  text: 'Start Bins Trip',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/start_bins_trip",
                                  visible: rules[:start_bins_trip],
                                  style: :button)

              cancel = { control_type: :link,
                         text: 'Cancel Tripheet',
                         url: "/raw_materials/deliveries/rmt_deliveries/#{id}/cancel_delivery_tripheet",
                         visible: rules[:cancel_delivery_tripheet],
                         style: :button }
              cancel.store(:prompt, 'Vehicle is already loaded, do you want to cancel?') if rules[:vehicle_loaded]
              section.add_control(cancel)

              section.add_control(control_type: :link,
                                  text: 'Print Tripsheet',
                                  url: "/rmd/finished_goods/print_tripsheet/#{rules[:vehicle_job_id]}",
                                  visible: rules[:cancel_delivery_tripheet],
                                  loading_window: true,
                                  style: :button)

              section.add_control(control_type: :link,
                                  text: 'Refresh Tripsheet',
                                  url: "/raw_materials/deliveries/rmt_deliveries/#{id}/refresh_delivery_tripheet",
                                  visible: rules[:refresh_tripsheet],
                                  style: :button)

              section.add_notice rules[:mrl_result_notice], notice_type: :warning if AppConst::CR_RMT.enforce_mrl_check? && !rules[:mrl_result_notice].nil_or_empty?
              section.form do |form|
                form.view_only!
                form.no_submit!
                form.row do |row|
                  row.column do |col|
                    col.add_field :id
                    col.add_field :season_id
                    col.add_field :farm_id
                    col.add_field :puc_id
                    col.add_field :orchard_id
                    col.add_field :farm_section
                    col.add_field :cultivar_id
                    if AppConst::CR_RMT.all_delivery_bins_of_same_type?
                      col.add_field :rmt_container_type_id
                      col.add_field :rmt_container_material_type_id
                      col.add_field :rmt_material_owner_party_role_id
                    end
                    col.add_field :rmt_delivery_destination_id
                    col.add_field :reference_number
                    col.add_field :truck_registration_number
                    col.add_field :qty_damaged_bins
                    col.add_field :qty_empty_bins
                  end

                  row.column do |col|
                    col.add_field :quantity_bins_with_fruit
                    col.add_field :bin_scan_mode
                    col.add_field :current
                    col.add_field :date_picked
                    col.add_field :received
                    col.add_field :date_delivered
                    col.add_field :delivery_tipped
                    col.add_field :tipping_complete_date_time
                    col.add_field :keep_open
                    col.add_field :active
                    col.add_field :batch_number
                    col.add_field :batch_number_updated_at
                    col.add_field :sample_bins
                  end
                end
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
