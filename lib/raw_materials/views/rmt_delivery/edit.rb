# frozen_string_literal: true

module RawMaterials
  module Deliveries
    module RmtDelivery
      class Edit
        extend RawMaterialsApp::ViewHelpers::QC

        def self.call(id, is_update: nil, form_values: nil, form_errors: nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          ui_rule = UiRules::Compiler.new(:rmt_delivery, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/rmt_deliveries',
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
                                  text: 'Manage Costs',
                                  url: "/list/rmt_delivery_costs/with_params?key=standard&rmt_delivery_costs.rmt_delivery_id=#{id}",
                                  behaviour: :popup,
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
                                  visible: rules[:cancel_delivery_tripheet],
                                  loading_window: true }

              refresh_tripsheet = { text: 'Refresh Tripsheet',
                                    url: "/raw_materials/deliveries/rmt_deliveries/#{id}/refresh_delivery_tripheet",
                                    visible: rules[:refresh_tripsheet] }

              tripsheet_items = [create_tripsheet, start_bins_trip, list_tripsheets, cancel_tripsheet, print_tripsheet, refresh_tripsheet]
              section.add_control(control_type: :dropdown_button,
                                  text: 'Tripsheets',
                                  items: tripsheet_items)

              section.add_notice rules[:mrl_result_notice], notice_type: :warning if AppConst::CR_RMT.enforce_mrl_check? && !rules[:mrl_result_notice].nil_or_empty?
              section.form do |form|
                form.caption 'Edit RMT Delivery'
                form.action "/raw_materials/deliveries/rmt_deliveries/#{id}"
                # form.remote! if remote
                form.method :update
                form.row do |row|
                  row.column do |col|
                    col.add_field :id
                    col.add_field :sample_bins
                    col.add_field :farm_id
                    col.add_field :puc_id
                    col.add_field :orchard_id
                    col.add_field :farm_section
                    col.add_field :cultivar_id
                    if AppConst::CR_RMT.all_delivery_bins_of_same_type
                      col.add_field :rmt_container_type_id
                      col.add_field :rmt_container_material_type_id
                      col.add_field :rmt_material_owner_party_role_id
                    end
                    col.add_field :rmt_delivery_destination_id
                    col.add_field :reference_number
                    col.add_field :truck_registration_number
                    col.add_field :qty_damaged_bins
                  end

                  row.column do |col|
                    col.add_field :qty_empty_bins
                    col.add_field :quantity_bins_with_fruit
                    col.add_field :bin_scan_mode
                    col.add_field :current
                    col.add_field :date_picked
                    col.add_field :received
                    col.add_field :date_delivered
                    col.add_field :delivery_tipped
                    col.add_field :tipping_complete_date_time
                    col.add_field :batch_number
                    col.add_field :batch_number_updated_at
                    col.add_field :qty_partial_bins
                    col.add_field :sample_bins_weighed
                    col.add_field :sample_weights_extrapolated_at
                    # col.add_field :keep_open
                  end
                end
              end
            end

            # QC Section from Helper
            qc_section(page, rules) if rules[:do_qc]

            unless is_update
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
                end
                section.add_grid('rmt_bins_deliveries',
                                 "/list/#{bin_type}rmt_bins/grid?key=standard&delivery_id=#{id}",
                                 caption: 'Bins')
              end
            end
          end
        end
      end
    end
  end
end
