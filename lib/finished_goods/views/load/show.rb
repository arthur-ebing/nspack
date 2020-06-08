# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module Load
      class Show # rubocop:disable Metrics/ClassLength
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/loads',
                                  style: :back_button)
              section.add_control(control_type: :link,
                                  text: ui_rule.form_object.back_caption,
                                  icon: :edit,
                                  url: ui_rule.form_object.back_action,
                                  prompt: ui_rule.form_object.back_prompt,
                                  visible: !ui_rule.form_object.back_action.nil?,
                                  style: :action_button)
              section.add_control(control_type: :link,
                                  text: 'Delete',
                                  icon: :checkoff,
                                  url: "/finished_goods/dispatch/loads/#{id}/delete",
                                  prompt: 'Are you sure, you want to delete this load?',
                                  visible: !ui_rule.form_object.allocated,
                                  style: :action_button)
              section.add_control(control_type: :link,
                                  text: 'Delete Temp Tail',
                                  url: "/finished_goods/dispatch/loads/#{id}/delete_temp_tail",
                                  prompt: 'Are you sure, you want to delete the temp tail on this load?',
                                  icon: :checkoff,
                                  visible: !ui_rule.form_object.shipped & !ui_rule.form_object.temp_tail.nil?,
                                  style: :action_button)
              if ui_rule.form_object.allocated
                section.add_control(control_type: :link,
                                    text: 'Dispatch Note',
                                    url: "/finished_goods/reports/dispatch_note/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Dispatch Note - Summarised',
                                    url: "/finished_goods/reports/dispatch_note_summarised/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Dispatch Picklist',
                                    url: "/finished_goods/reports/picklist/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Addendum',
                                    url: "/finished_goods/reports/addendum/#{id}",
                                    loading_window: true,
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'Verified Gross Mass',
                                    url: "/finished_goods/reports/verified_gross_mass/#{id}",
                                    visible: ui_rule.form_object.container,
                                    loading_window: true,
                                    style: :button)
              end
            end

            page.form do |form|
              form.action ui_rule.form_object.action
              form.submit_captions ui_rule.form_object.caption
              form.fold_up do |fold|
                fold.caption 'Parties'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :customer_party_role_id
                    col.add_field :consignee_party_role_id
                    col.add_field :final_receiver_party_role_id
                  end
                  row.column do |col|
                    col.add_field :exporter_party_role_id
                    col.add_field :billing_client_party_role_id
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Load Details'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :id
                    col.add_field :load_id
                    col.add_field :order_number
                    col.add_field :customer_order_number
                    col.add_field :customer_reference
                    col.add_field :depot_id
                  end
                  row.column do |col|
                    col.add_field :status
                    col.add_field :exporter_certificate_code
                    col.add_field :edi_file_name
                    col.add_field :shipped_at
                    col.add_field :requires_temp_tail
                    col.add_field :temp_tail_pallet_number
                    col.add_field :temp_tail
                  end
                end
              end
              if ui_rule.form_object.edi
                form.fold_up do |fold|
                  fold.caption 'EDI'
                  fold.open!
                  fold.add_grid('edi_po',
                                "/list/edi_po/grid?key=standard&record_id=#{id}",
                                caption: 'EDI Transactions',
                                height: 10)
                  fold.row do |row|
                    row.column do |col|
                      col.add_control(control_type: :link,
                                      text: 'Re-Send PO',
                                      url: "/finished_goods/dispatch/loads/#{id}/re_send_po_edi",
                                      icon: :plus,
                                      behaviour: :popup,
                                      style: :action_button)
                    end
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Voyage Ports and Locations'
                fold.row do |row|
                  row.column do |col|
                    col.add_field :voyage_type_id
                    col.add_field :vessel_id
                    col.add_field :voyage_number
                    col.add_field :year
                    col.add_field :final_destination_id
                    col.add_field :transfer_load
                    col.add_control(control_type: :link,
                                    text: 'Go to Voyage',
                                    url: "/finished_goods/dispatch/voyages/#{ui_rule.form_object.voyage_id}",
                                    style: :action_button)
                  end
                  row.column do |col|
                    col.add_field :spacer
                    col.add_field :pol_port_id
                    col.add_field :eta
                    col.add_field :ata
                    col.add_field :pod_port_id
                    col.add_field :etd
                    col.add_field :atd
                  end
                end
              end
              form.fold_up do |fold|
                fold.caption 'Load Voyage'
                fold.row do |row|
                  row.column do |col|
                    col.add_field :shipping_line_party_role_id
                    col.add_field :shipper_party_role_id
                    col.add_field :booking_reference
                  end
                  row.column do |col|
                    col.add_field :memo_pad
                  end
                end
              end
              if ui_rule.form_object.vehicle
                form.fold_up do |fold|
                  fold.caption 'Load Vehicle - Truck Arrival'
                  fold.row do |row|
                    row.column do |col|
                      col.add_field :vehicle_number
                      col.add_field :driver
                      col.add_field :driver_number
                      col.add_control(control_type: :link,
                                      text: 'Edit Truck Arrival',
                                      url: "/finished_goods/dispatch/loads/#{id}/truck_arrival",
                                      icon: :edit,
                                      visible: !ui_rule.form_object.loaded,
                                      behaviour: :popup,
                                      style: :action_button)
                    end
                    row.column do |col|
                      col.add_field :vehicle_type
                      col.add_field :haulier
                      col.add_field :vehicle_weight_out
                    end
                  end
                end
              end
              if ui_rule.form_object.container
                form.fold_up do |fold|
                  fold.caption 'Load Container'
                  fold.row do |row|
                    row.column do |col|
                      col.add_field :container_code
                      col.add_field :container_vents
                      col.add_field :container_seal_code
                      col.add_field :internal_container_code
                      col.add_field :stack_type
                    end
                    row.column do |col|
                      col.add_field :temperature_rhine
                      col.add_field :temperature_rhine2
                      if AppConst::VGM_REQUIRED
                        col.add_field :max_payload
                        col.add_field :tare_weight
                        col.add_field :actual_payload
                      end
                      col.add_field :max_gross_weight
                      col.add_field :cargo_temperature
                      col.add_field :verified_gross_weight
                      col.add_field :verified_gross_weight_date
                    end
                  end
                end
              end
            end
            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: ui_rule.form_object.step
              section.show_border!
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Allocate Pallets',
                                  url: "/finished_goods/dispatch/loads/#{id}/allocate",
                                  visible: !ui_rule.form_object.vehicle,
                                  style: :action_button)
              section.add_control(control_type: :link,
                                  text: 'Truck Arrival',
                                  url: "/finished_goods/dispatch/loads/#{id}/truck_arrival",
                                  icon: :edit,
                                  visible: ui_rule.form_object.allocated & !ui_rule.form_object.vehicle,
                                  behaviour: :popup,
                                  style: :action_button)
              section.add_control(control_type: :link,
                                  text: 'Temp Tail',
                                  url: "/finished_goods/dispatch/loads/#{id}/temp_tail",
                                  icon: :edit,
                                  visible: ui_rule.form_object.loaded & !ui_rule.form_object.shipped,
                                  behaviour: :popup,
                                  style: :action_button)
              section.add_grid('stock_pallets',
                               "/list/stock_pallets/grid?key=on_load&load_id=#{id}",
                               caption: 'Load Pallets',
                               height: 40)
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
