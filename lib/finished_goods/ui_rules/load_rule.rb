# frozen_string_literal: true

module UiRules
  class LoadRule < Base # rubocop:disable ClassLength
    def generate_rules
      @repo = FinishedGoodsApp::LoadRepo.new

      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show ship].include? @mode
      add_rules if @mode == :ship
      set_allocate_fields if @mode == :allocate
      add_behaviours

      form_name 'load'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      # Parties and Locations
      customer_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.customer_party_role_id)&.party_name
      exporter_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.exporter_party_role_id)&.party_name
      billing_client_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.billing_client_party_role_id)&.party_name
      consignee_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.consignee_party_role_id)&.party_name
      final_receiver_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.final_receiver_party_role_id)&.party_name
      fields[:customer_party_role_id] = { renderer: :label, with_value: customer_label, caption: 'Customer' }
      fields[:exporter_party_role_id] = { renderer: :label, with_value: exporter_label, caption: 'Exporter' }
      fields[:billing_client_party_role_id] = { renderer: :label, with_value: billing_client_label, caption: 'Billing Client' }
      fields[:consignee_party_role_id] = { renderer: :label, with_value: consignee_label, caption: 'Consignee' }
      fields[:final_receiver_party_role_id] = { renderer: :label, with_value: final_receiver_label, caption: 'Final Receiver' }

      # Load Details
      depot_label = MasterfilesApp::DepotRepo.new.find_depot(@form_object.depot_id)&.depot_code
      fields[:order_number] = { renderer: :label }
      fields[:customer_order_number] = { renderer: :label }
      fields[:customer_reference] = { renderer: :label }
      fields[:depot_id] = { renderer: :label, with_value: depot_label, caption: 'Depot' }
      fields[:exporter_certificate_code] = { renderer: :label }
      fields[:edi_file_name] = { renderer: :label }
      fields[:shipped_at] = { renderer: :label }
      fields[:shipped] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }

      # Voyage Ports
      voyage_type_code_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.voyage_type_code
      voyage_vessel_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.vessel_code
      voyage_number_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.voyage_number
      voyage_year_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.year
      pol_voyage_port_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.port_code
      pod_voyage_port_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pod_voyage_port_id)&.port_code
      final_destination_label = MasterfilesApp::DestinationRepo.new.find_city(@form_object.final_destination_id)&.city_name
      fields[:voyage_type_id] = { renderer: :label, with_value: voyage_type_code_label, caption: 'Voyage Type' }
      fields[:vessel_id] = { renderer: :label, with_value: voyage_vessel_label, caption: 'Vessel' }
      fields[:voyage_number] = { renderer: :label, with_value: voyage_number_label, caption: 'Voyage Number' }
      fields[:year] = { renderer: :label, with_value: voyage_year_label, caption: 'Year' }
      fields[:pol_port_id] = { renderer: :label, with_value: pol_voyage_port_label, caption: 'POL Voyage Port' }
      fields[:pod_port_id] = { renderer: :label, with_value: pod_voyage_port_label, caption: 'POD Voyage Port' }
      fields[:final_destination_id] = { renderer: :label, with_value: final_destination_label, caption: 'Final Destination' }
      fields[:transfer_load] = { renderer: :label, as_boolean: true }

      # Load Voyage
      shipping_line_party_role_id = FinishedGoodsApp::LoadVoyageRepo.new.find_load_voyage(@form_object.id)&.shipping_line_party_role_id
      shipper_party_role_id = FinishedGoodsApp::LoadVoyageRepo.new.find_load_voyage(@form_object.id)&.shipper_party_role_id
      shipping_line_label = MasterfilesApp::PartyRepo.new.find_party_role(shipping_line_party_role_id)&.party_name
      shipper_label = MasterfilesApp::PartyRepo.new.find_party_role(shipper_party_role_id)&.party_name
      booking_reference_label = FinishedGoodsApp::LoadVoyageRepo.new.find_load_voyage(@form_object.id)&.booking_reference
      memo_pad_label = FinishedGoodsApp::LoadVoyageRepo.new.find_load_voyage(@form_object.id)&.memo_pad
      fields[:shipping_line_party_role_id] = { renderer: :label, with_value: shipping_line_label, caption: 'Shipping Line' }
      fields[:shipper_party_role_id] = { renderer: :label, with_value: shipper_label, caption: 'Shipper' }
      fields[:booking_reference] = { renderer: :label, with_value: booking_reference_label, caption: 'Booking Reference' }
      fields[:memo_pad] = { renderer: :label, with_value: memo_pad_label, caption: 'Memo Pad' }
    end

    def set_allocate_fields # rubocop:disable Metrics/AbcSize
      depot_label = MasterfilesApp::DepotRepo.new.find_depot(@form_object.depot_id)&.depot_code
      fields[:depot_id] = { renderer: :label, with_value: depot_label, caption: 'Depot' }
      voyage_code_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.voyage_code
      pol_voyage_port_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.port_code
      pod_voyage_port_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pod_voyage_port_id)&.port_code
      fields[:voyage_code] = { renderer: :label, with_value: voyage_code_label, caption: 'Voyage Code' }
      fields[:pol_port_id] = { renderer: :label, with_value: pol_voyage_port_label, caption: 'POL Voyage Port' }
      fields[:pod_port_id] = { renderer: :label, with_value: pod_voyage_port_label, caption: 'POD Voyage Port' }
      fields[:id] = { renderer: :label, with_value: @form_object.id, caption: 'Load Id' }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        # Parties
        customer_party_role_id: { renderer: :select,
                                  options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_CUSTOMER),
                                  disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_CUSTOMER),
                                  caption: 'Customer',
                                  required: true,
                                  prompt: true },
        billing_client_party_role_id: { renderer: :select,
                                        options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_BILLING_CLIENT),
                                        disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_BILLING_CLIENT),
                                        caption: 'Billing Client',
                                        required: true,
                                        prompt: true },
        exporter_party_role_id: { renderer: :select,
                                  options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_EXPORTER),
                                  disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_EXPORTER),
                                  caption: 'Exporter',
                                  required: true,
                                  prompt: true },
        consignee_party_role_id: { renderer: :select,
                                   options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_CONSIGNEE),
                                   disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_CONSIGNEE),
                                   caption: 'Consignee',
                                   required: true,
                                   prompt: true },
        final_receiver_party_role_id: { renderer: :select,
                                        options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_FINAL_RECEIVER),
                                        disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_FINAL_RECEIVER),
                                        caption: 'Final Receiver',
                                        required: true,
                                        prompt: true },

        # Load Details
        order_number: {},
        customer_order_number: {},
        customer_reference: {},
        depot_id: { renderer: :select,
                    options: MasterfilesApp::DepotRepo.new.for_select_depots,
                    disabled_options: MasterfilesApp::DepotRepo.new.for_select_inactive_depots,
                    caption: 'Depot',
                    required: true },
        exporter_certificate_code: {},
        edi_file_name: { renderer: :label },
        shipped_at: { renderer: :label },
        shipped: { renderer: :label, as_boolean: true  },

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
                     disabled_options: MasterfilesApp::VesselRepo.new.for_select_vessels(voyage_type_id: @form_object.voyage_type_id, active: false),
                     caption: 'Vessel',
                     prompt: true,
                     required: true },
        voyage_number: { required: true },
        year: { renderer: :input, subtype: :integer,
                required: true },
        pol_port_id: { renderer: :select,
                       options: MasterfilesApp::PortRepo.new.for_select_ports(port_type_code: AppConst::PORT_TYPE_POL, voyage_type_id: @form_object.voyage_type_id),
                       disabled_options: MasterfilesApp::PortRepo.new.for_select_ports(port_type_code: AppConst::PORT_TYPE_POL, voyage_type_id: @form_object.voyage_type_id, active: false),
                       selected: FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pol_voyage_port_id)&.port_id,
                       caption: 'POL Voyage Port',
                       prompt: true,
                       required: true },
        pod_port_id: { renderer: :select,
                       options: MasterfilesApp::PortRepo.new.for_select_ports(port_type_code: AppConst::PORT_TYPE_POD, voyage_type_id: @form_object.voyage_type_id),
                       disabled_options: MasterfilesApp::PortRepo.new.for_select_ports(port_type_code: AppConst::PORT_TYPE_POD, voyage_type_id: @form_object.voyage_type_id, active: false),
                       selected: FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port_flat(@form_object.pod_voyage_port_id)&.port_id,
                       caption: 'POD Voyage Port',
                       prompt: true,
                       required: true },
        final_destination_id: { renderer: :select,
                                options: MasterfilesApp::DestinationRepo.new.for_select_destination_cities,
                                disabled_options: MasterfilesApp::DestinationRepo.new.for_select_inactive_destination_cities,
                                caption: 'Final Destination',
                                prompt: true,
                                required: true },
        transfer_load: { renderer: :checkbox },

        # Load Voyage
        shipping_line_party_role_id: { renderer: :select,
                                       options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_SHIPPING_LINE),
                                       disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_SHIPPING_LINE),
                                       caption: 'Shipping Line',
                                       prompt: true },
        shipper_party_role_id: { renderer: :select,
                                 options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_SHIPPER),
                                 disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_SHIPPER),
                                 caption: 'Shipper',
                                 prompt: true },
        booking_reference: {},
        memo_pad: { renderer: :textarea, rows: 7 },

        # Allocate Pallets
        pallet_list: { renderer: :textarea, rows: 12,
                       placeholder: 'Paste pallet numbers here',
                       caption: 'Allocate' }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new
      @form_object = @repo.find_load_flat(@options[:id])
      @form_object = OpenStruct.new(@form_object.to_h.merge!(pallet_list: nil))
    end

    def make_new_form_object
      @form_object = OpenStruct.new(depot_id: (@repo.where_hash(:depots, depot_code: AppConst::DEFAULT_DEPOT) || {})[:id],
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
                                    shipped: nil,
                                    transfer_load: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :customer_party_role_id, notify: [{ url: '/finished_goods/dispatch/loads/customer_changed' }] if @mode == :new
        behaviour.dropdown_change :exporter_party_role_id, notify: [{ url: '/finished_goods/dispatch/loads/exporter_changed' }] if @mode == :new
        behaviour.dropdown_change :voyage_type_id, notify: [{ url: '/finished_goods/dispatch/loads/voyage_type_changed' }] if %i[new edit].include? @mode
        behaviour.dropdown_change :pod_port_id, notify: [{ url: '/finished_goods/dispatch/loads/pod_port_changed' }] if @mode == :new
      end
    end

    def add_rules
      rules[:can_unship] = @form_object.shipped && Crossbeams::Config::UserPermissions.can_user?(@options[:user], :load, :can_unship)

      rules[:can_ship] = !@form_object.shipped &&
                         Crossbeams::Config::UserPermissions.can_user?(@options[:user], :load, :can_ship) &&
                         !FinishedGoodsApp::LoadVehicleRepo.new.find_load_vehicle_from(load_id: @form_object.id).nil_or_empty?
    end
  end
end
