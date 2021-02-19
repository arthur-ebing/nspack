# frozen_string_literal: true

module UiRules
  class LoadRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = FinishedGoodsApp::LoadRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object

      apply_form_values

      add_progress_step
      add_controls
      add_behaviours

      common_values_for_fields common_fields
      set_show_fields if %i[show allocate].include? @mode
      form_name 'load'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      # Parties and Locations
      fields[:customer_party_role_id] = { renderer: :label, with_value: @form_object.customer, caption: 'Customer' }
      fields[:exporter_party_role_id] = { renderer: :label, with_value: @form_object.exporter, caption: 'Exporter' }
      fields[:billing_client_party_role_id] = { renderer: :label, with_value: @form_object.billing_client, caption: 'Billing Client' }
      fields[:consignee_party_role_id] = { renderer: :label, with_value: @form_object.consignee, caption: 'Consignee' }
      fields[:final_receiver_party_role_id] = { renderer: :label, with_value: @form_object.final_receiver, caption: 'Final Receiver' }
      fields[:status] = { renderer: :label }

      # Load Details
      voyage_code_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.voyage_code
      depot_label = MasterfilesApp::DepotRepo.new.find_depot(@form_object.depot_id)&.depot_code
      fields[:id] = { renderer: :label, with_value: @form_object.id, caption: 'Load' }
      fields[:voyage_code] = { renderer: :label, with_value: voyage_code_label, caption: 'Voyage Code' }
      fields[:depot_id] = { renderer: :label, with_value: depot_label, caption: 'Depot' }
      fields[:rmt_load] = { renderer: :label, as_boolean: true, caption: 'RMT Load' }
      fields[:order_number] = { renderer: :label }
      fields[:customer_order_number] = { renderer: :label }
      fields[:customer_reference] = { renderer: :label }
      fields[:exporter_certificate_code] = { renderer: :label }
      fields[:edi_file_name] = { renderer: :label }
      fields[:shipped_at] = { renderer: :label }
      fields[:requires_temp_tail] = { renderer: :label, as_boolean: true }
      fields[:temp_tail_pallet_number] = { renderer: :label, caption: 'Temp Tail Pallet', hide_on_load: @form_object.temp_tail.nil_or_empty? }
      fields[:temp_tail] = { renderer: :label, caption: 'Temp Tail', hide_on_load: @form_object.temp_tail.nil_or_empty? }
      fields[:active] = { renderer: :label, as_boolean: true }

      # Voyage Ports
      pol = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)
      pod = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pod_voyage_port_id)
      final_destination = MasterfilesApp::DestinationRepo.new.find_city(@form_object.final_destination_id)&.city_name
      fields[:voyage_type_id] = { renderer: :label, with_value: pol&.voyage_type_code, caption: 'Voyage Type' }
      fields[:vessel_id] = { renderer: :label, with_value: pol&.vessel_code, caption: 'Vessel' }
      fields[:voyage_number] = { renderer: :label, with_value: pol&.voyage_number, caption: 'Voyage Number' }
      fields[:year] = { renderer: :label, with_value: pol&.year, caption: 'Year' }
      fields[:final_destination_id] = { renderer: :label, with_value: final_destination, caption: 'Final Destination' }
      fields[:transfer_load] = { renderer: :label, as_boolean: true }
      fields[:pod_port_id] = { renderer: :label, with_value: pod&.port_code, caption: 'POD Voyage Port' }
      fields[:eta] = { renderer: :label, caption: 'ETA' }
      fields[:ata] = { renderer: :label, caption: 'ATA' }
      fields[:pol_port_id] = { renderer: :label, with_value: pol&.port_code, caption: 'POL Voyage Port' }
      fields[:etd] = { renderer: :label, caption: 'ETD' }
      fields[:atd] = { renderer: :label, caption: 'ATD' }

      # Load Voyage
      fields[:shipping_line_party_role_id] = { renderer: :label, with_value: @form_object.shipping_line, caption: 'Shipping Line' }
      fields[:shipper_party_role_id] = { renderer: :label, with_value: @form_object.shipper, caption: 'Shipper' }
      fields[:booking_reference] = { renderer: :label }
      fields[:memo_pad] = { renderer: :label }

      # Load Vehicles
      load_vehicle_id = @repo.get_id(:load_vehicles, load_id: @form_object.id)
      vehicle = FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle_flat(load_vehicle_id)
      vehicle_fields = {}
      vehicle_fields[:vehicle_number] = { renderer: :label, with_value: vehicle&.vehicle_number }
      vehicle_fields[:driver] = { renderer: :label, with_value: vehicle&.driver_name }
      vehicle_fields[:driver_number] = { renderer: :label, with_value: vehicle&.driver_cell_number }
      vehicle_fields[:vehicle_type] = { renderer: :label, with_value: vehicle&.vehicle_type_code }
      vehicle_fields[:haulier] = { renderer: :label, with_value: vehicle&.haulier }
      vehicle_fields[:vehicle_weight_out] = { renderer: :label, with_value: vehicle&.vehicle_weight_out }
      fields.merge!(vehicle_fields.each { |_, v| v[:invisible] = vehicle.nil? })

      # Load Container
      load_container_id = @repo.get_id(:load_containers, load_id: @form_object.id)
      container = FinishedGoodsApp::LoadContainerRepo.new.find_load_container_flat(load_container_id)
      container_fields = {}
      container_fields[:container_code] = { renderer: :label, with_value: container&.container_code }
      container_fields[:container_vents] = { renderer: :label, with_value: container&.container_vents }
      container_fields[:container_seal_code] = { renderer: :label, with_value: container&.container_seal_code }
      container_fields[:internal_container_code] = { renderer: :label, with_value: container&.internal_container_code }
      container_fields[:stack_type] = { renderer: :label, with_value: "#{container&.stack_type_code} - #{container&.stack_type_description}" }
      container_fields[:temperature_rhine] = { renderer: :label, with_value: container&.container_temperature_rhine }
      container_fields[:temperature_rhine2] = { renderer: :label, with_value: container&.container_temperature_rhine2 }
      container_fields[:max_gross_weight] = { renderer: :label, with_value: container&.max_gross_weight }
      container_fields[:tare_weight] = { renderer: :label, with_value: container&.tare_weight }
      container_fields[:max_payload] = { renderer: :label, with_value: container&.max_payload }
      container_fields[:actual_payload] = { renderer: :label, with_value: container&.actual_payload }
      container_fields[:cargo_temperature] = { renderer: :label, with_value: "#{container&.cargo_temperature_code} - #{container&.set_point_temperature}" }
      container_fields[:verified_gross_weight] = { renderer: :label, with_value: container&.verified_gross_weight }
      container_fields[:verified_gross_weight_date] = { renderer: :label, with_value: container&.verified_gross_weight_date }
      fields.merge!(container_fields.each { |_, v| v[:invisible] = container.nil? })

      # Titan Addendum
      addendum = FinishedGoodsApp::TitanRepo.new.find_titan_addendum(@form_object.id)
      addendum_fields = {}
      fields[:location_of_issue] = { renderer: :label }
      addendum_fields[:addendum_status] = { renderer: :label, with_value: addendum&.addendum_status }
      addendum_fields[:best_regime_code] = { renderer: :label, with_value: addendum&.best_regime_code }
      addendum_fields[:verification_status] = { renderer: :label, with_value: addendum&.verification_status }
      addendum_fields[:addendum_validations] = { renderer: :label, with_value: addendum&.addendum_validations }
      addendum_fields[:available_regime_code] = { renderer: :label, with_value: addendum&.available_regime_code }
      addendum_fields[:e_cert_response_message] = { renderer: :label, with_value: addendum&.e_cert_response_message }
      addendum_fields[:e_cert_hub_tracking_number] = { renderer: :label, with_value: addendum&.e_cert_hub_tracking_number }
      addendum_fields[:e_cert_hub_tracking_status] = { renderer: :label, with_value: addendum&.e_cert_hub_tracking_status }
      addendum_fields[:e_cert_application_status] = { renderer: :label, with_value: addendum&.e_cert_application_status }
      addendum_fields[:phyt_clean_verification_key] = { renderer: :label, with_value: addendum&.phyt_clean_verification_key }
      addendum_fields[:export_certification_status] = { renderer: :label, with_value: addendum&.export_certification_status }
      addendum_fields[:cancelled_status] = { renderer: :label, with_value: addendum&.cancelled_status }
      addendum_fields[:cancelled_at] = { renderer: :label, with_value: addendum&.cancelled_at }

      fields.merge!(addendum_fields.each { |_, v| v[:invisible] = addendum.nil? })
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      { # Parties
        customer_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_CUSTOMER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_CUSTOMER),
                                  caption: 'Customer',
                                  required: true,
                                  prompt: true },
        billing_client_party_role_id: { renderer: :select,
                                        options: @party_repo.for_select_party_roles(AppConst::ROLE_BILLING_CLIENT),
                                        disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_BILLING_CLIENT),
                                        caption: 'Billing Client',
                                        required: true,
                                        prompt: true },
        exporter_party_role_id: { renderer: :select,
                                  options: @party_repo.for_select_party_roles(AppConst::ROLE_EXPORTER),
                                  disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_EXPORTER),
                                  caption: 'Exporter',
                                  required: true,
                                  prompt: true },
        consignee_party_role_id: { renderer: :select,
                                   options: @party_repo.for_select_party_roles(AppConst::ROLE_CONSIGNEE),
                                   disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_CONSIGNEE),
                                   caption: 'Consignee',
                                   required: true,
                                   prompt: true },
        final_receiver_party_role_id: { renderer: :select,
                                        options: @party_repo.for_select_party_roles(AppConst::ROLE_FINAL_RECEIVER),
                                        disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_FINAL_RECEIVER),
                                        caption: 'Final Receiver',
                                        required: true,
                                        prompt: true },
        status: { renderer: :label },

        # Load Details
        id: { renderer: :label,
              caption: 'Load' },
        load_id: { hide_on_load: true },
        order_number: {},
        customer_order_number: {},
        customer_reference: {},
        depot_id: { renderer: :select,
                    options: MasterfilesApp::DepotRepo.new.for_select_depots,
                    disabled_options: MasterfilesApp::DepotRepo.new.for_select_inactive_depots,
                    caption: 'Depot',
                    required: true },
        rmt_load: { renderer: :checkbox, as_boolean: true },
        exporter_certificate_code: {},
        edi_file_name: { renderer: :label },
        shipped_at: { renderer: rules[:can_unship] ? :datetime : :label,
                      required: true },
        requires_temp_tail: { renderer: :checkbox, as_boolean: true },

        # Voyage Ports
        voyage_type_id: { renderer: :select,
                          options: MasterfilesApp::VoyageTypeRepo.new.for_select_voyage_types,
                          disabled_options: MasterfilesApp::VoyageTypeRepo.new.for_select_inactive_voyage_types,
                          caption: 'Voyage Type',
                          prompt: true,
                          required: true,
                          disabled: false },
        vessel_id: { renderer: :select,
                     options: MasterfilesApp::VesselRepo.new.for_select_vessels(voyage_type_id: @form_object.voyage_type_id),
                     disabled_options: MasterfilesApp::VesselRepo.new.for_select_inactive_vessels(voyage_type_id: @form_object.voyage_type_id),
                     caption: 'Vessel',
                     prompt: true,
                     required: true },
        voyage_number: { required: true },
        year: { renderer: :input,
                subtype: :integer,
                required: true },
        final_destination_id: { renderer: :select,
                                options: MasterfilesApp::DestinationRepo.new.for_select_destination_cities,
                                disabled_options: MasterfilesApp::DestinationRepo.new.for_select_inactive_destination_cities,
                                caption: 'Final Destination',
                                prompt: true,
                                required: true },
        transfer_load: { renderer: :checkbox },
        pol_port_id: { renderer: :select,
                       options: MasterfilesApp::PortRepo.new.for_select_ports(port_type_code: AppConst::PORT_TYPE_POL, voyage_type_id: @form_object.voyage_type_id),
                       disabled_options: MasterfilesApp::PortRepo.new.for_select_inactive_ports(port_type_code: AppConst::PORT_TYPE_POL, voyage_type_id: @form_object.voyage_type_id),
                       selected: FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.port_id,
                       caption: 'POL Voyage Port',
                       prompt: true,
                       required: true },
        pod_port_id: { renderer: :select,
                       options: MasterfilesApp::PortRepo.new.for_select_ports(port_type_code: AppConst::PORT_TYPE_POD, voyage_type_id: @form_object.voyage_type_id),
                       disabled_options: MasterfilesApp::PortRepo.new.for_select_inactive_ports(port_type_code: AppConst::PORT_TYPE_POD, voyage_type_id: @form_object.voyage_type_id),
                       selected: FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pod_voyage_port_id)&.port_id,
                       caption: 'POD Voyage Port',
                       prompt: true,
                       required: true },

        # Load Voyage
        shipping_line_party_role_id: { renderer: :select,
                                       options: @party_repo.for_select_party_roles(AppConst::ROLE_SHIPPING_LINE),
                                       disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_SHIPPING_LINE),
                                       caption: 'Shipping Line',
                                       prompt: true },
        shipper_party_role_id: { renderer: :select,
                                 options: @party_repo.for_select_party_roles(AppConst::ROLE_SHIPPER),
                                 disabled_options: @party_repo.for_select_inactive_party_roles(AppConst::ROLE_SHIPPER),
                                 caption: 'Shipper',
                                 prompt: true },
        booking_reference: {},
        memo_pad: { renderer: :textarea, rows: 7 },

        # Allocate Pallets
        pallet_list: { renderer: :textarea, rows: 12,
                       placeholder: 'Paste pallet numbers here',
                       caption: 'Allocate',
                       required: true },
        # Temp Tail
        temp_tail_pallet_number: { renderer: :select,
                                   options: @repo.select_values(:pallets, :pallet_number, load_id: @options[:id]),
                                   caption: 'Pallet',
                                   hide_on_load: @mode != :temp_tail,
                                   required: true },
        temp_tail: { renderer: :input,
                     hide_on_load: @mode != :temp_tail,
                     required: true },
        spacer: { hide_on_load: true },
        # Addendum
        location_of_issue: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      hash = @repo.find_load_flat(@options[:id]).to_h
      hash[:pallet_list] = nil
      @form_object = OpenStruct.new(hash)
    end

    def make_new_form_object
      @form_object = OpenStruct.new(depot_id: @repo.get_id(:depots, depot_code: AppConst::DEFAULT_DEPOT),
                                    rmt_load: false,
                                    customer_party_role_id: nil,
                                    consignee_party_role_id: nil,
                                    billing_client_party_role_id: nil,
                                    exporter_party_role_id: nil,
                                    final_receiver_party_role_id: nil,
                                    final_destination_id: nil,
                                    year: DateTime.now.year,
                                    pol_voyage_port_id: nil,
                                    pod_voyage_port_id: nil,
                                    order_number: nil,
                                    edi_file_name: nil,
                                    customer_order_number: nil,
                                    customer_reference: nil,
                                    exporter_certificate_code: nil,
                                    shipped_at: nil,
                                    shipped: false,
                                    loaded: false,
                                    requires_temp_tail: AppConst::TEMP_TAIL_REQUIRED_TO_SHIP,
                                    transfer_load: nil,
                                    location_of_issue: nil)
    end

    private

    def add_progress_step
      steps = ['Allocate Pallets', 'Truck Arrival', 'Load Truck', 'Ship', 'Finished']
      step = 0
      step = 1 if @form_object.allocated
      step = 2 if @form_object.vehicle
      step = 3 if @form_object.loaded || @form_object.temp_tail
      step = 4 if @form_object.shipped

      @form_object = OpenStruct.new(@form_object.to_h.merge(steps: steps, step: step))
    end

    def add_controls # rubocop:disable Metrics/AbcSize
      id = @options[:id]
      edit = { control_type: :link,
               style: :action_button,
               text: 'Edit',
               url: "/finished_goods/dispatch/loads/#{id}/edit",
               prompt: 'Are you sure, you want to edit this load?',
               icon: :edit }
      delete = { control_type: :link,
                 style: :action_button,
                 text: 'Delete',
                 url: "/finished_goods/dispatch/loads/#{id}/delete",
                 prompt: 'Are you sure, you want to delete this load?',
                 icon: :checkoff }
      allocate = { control_type: :link,
                   style: :action_button,
                   text: 'Allocate Pallets',
                   url: "/finished_goods/dispatch/loads/#{id}/allocate",
                   icon: :checkon }
      truck_arrival = { control_type: :link,
                        style: :action_button,
                        text: 'Truck Arrival',
                        url: "/finished_goods/dispatch/loads/#{id}/truck_arrival",
                        icon: :checkon,
                        behaviour: :popup }
      edit_truck_arrival = { control_type: :link,
                             text: 'Edit Truck Arrival',
                             url: "/finished_goods/dispatch/loads/#{id}/truck_arrival",
                             icon: :edit,
                             behaviour: :popup,
                             style: :action_button }
      delete_truck_arrival = { control_type: :link,
                               style: :action_button,
                               text: 'Delete Truck Arrival',
                               url: "/finished_goods/dispatch/loads/#{id}/delete_load_vehicle",
                               prompt: 'Are you sure, you want to delete the vehicle from this load?',
                               icon: :back }
      load_truck = { control_type: :link,
                     style: :action_button,
                     text: 'Load Truck',
                     url: "/finished_goods/dispatch/loads/#{id}/load_truck",
                     icon: :checkon }
      unload_truck = { control_type: :link,
                       style: :action_button,
                       text: 'Unload Truck',
                       url: "/finished_goods/dispatch/loads/#{id}/unload_truck",
                       prompt: 'Are you sure, you want to unload this load?',
                       visible: @form_object.loaded,
                       icon: :back }
      tail = { control_type: :link,
               style: :action_button,
               text: 'Temp Tail',
               url: "/finished_goods/dispatch/loads/#{id}/temp_tail",
               icon: :checkon,
               behaviour: :popup }
      delete_tail = { control_type: :link,
                      style: :action_button,
                      text: 'Delete Temp Tail',
                      url: "/finished_goods/dispatch/loads/#{id}/delete_temp_tail",
                      prompt: 'Are you sure, you want to delete the temp tail on this load?',
                      visible: @form_object.temp_tail,
                      icon: :back }
      ship = { control_type: :link,
               style: :action_button,
               text: 'Ship',
               url: "/finished_goods/dispatch/loads/#{id}/ship",
               icon: :checkon }
      unship = { control_type: :link,
                 style: :action_button,
                 text: 'Unship',
                 url: "/finished_goods/dispatch/loads/#{id}/unship",
                 prompt: 'Are you sure, you want to unship this load?',
                 icon: :back }
      addendum = { control_type: :link,
                   style: :action_button,
                   text: 'Titan Addendum',
                   visible: @form_object.container & AppConst::CR_FG.do_titan_addenda?,
                   url: "/finished_goods/dispatch/loads/#{id}/titan_addendum",
                   icon: :edit }
      update_otmc = { control_type: :link,
                      style: :action_button,
                      text: 'Update Phyto Data',
                      url: "/finished_goods/dispatch/loads/#{id}/update_otmc",
                      prompt: 'Are you sure, you want to update the OTMC Results for this load?',
                      icon: :plus }

      case @form_object.step
      when 0
        progress_controls = [allocate]
        instance_controls = [edit, delete]
      when 1
        progress_controls = [allocate, truck_arrival]
        instance_controls = [edit]
      when 2
        progress_controls = [allocate, edit_truck_arrival, delete_truck_arrival, load_truck]
        instance_controls = [edit]
      when 3
        progress_controls = [unload_truck, delete_tail, tail, ship]
        instance_controls = [edit]
      when 4
        progress_controls = [unship, addendum, update_otmc]
        instance_controls = [edit]
      else
        progress_controls = []
        instance_controls = []
      end

      @form_object = OpenStruct.new(@form_object.to_h.merge(progress_controls: progress_controls, instance_controls: instance_controls))
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :customer_party_role_id, notify: [{ url: '/finished_goods/dispatch/loads/customer_changed' }] if @mode == :new
        behaviour.dropdown_change :exporter_party_role_id, notify: [{ url: '/finished_goods/dispatch/loads/exporter_changed' }] if @mode == :new
        behaviour.dropdown_change :voyage_type_id, notify: [{ url: '/finished_goods/dispatch/loads/voyage_type_changed' }] if %i[new edit].include? @mode
        behaviour.dropdown_change :pod_port_id, notify: [{ url: '/finished_goods/dispatch/loads/pod_port_changed' }] if @mode == :new
      end
    end
  end
end
