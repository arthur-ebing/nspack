# frozen_string_literal: true

module UiRules
  class LoadRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::LoadRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'load'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      # depot_location_label = FinishedGoodsApp::DestinationRepo.new.find_destination_depot(@form_object.depot_id)&.depot_code
      depot_label = @repo.find(:destination_depots, MasterfilesApp::DestinationRepo, @form_object.depot_id)&.depot_code
      # customer_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.customer_party_role_id)&.id
      customer_label = @repo.find(:party_roles, MasterfilesApp::PartyRepo, @form_object.customer_party_role_id)&.id
      # consignee_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.consignee_party_role_id)&.id
      consignee_label = @repo.find(:party_roles, MasterfilesApp::PartyRepo, @form_object.consignee_party_role_id)&.id
      # billing_client_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.billing_client_party_role_id)&.id
      billing_client_label = @repo.find(:party_roles, MasterfilesApp::PartyRepo, @form_object.billing_client_party_role_id)&.id
      # exporter_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.exporter_party_role_id)&.id
      exporter_label = @repo.find(:party_roles, MasterfilesApp::PartyRepo, @form_object.exporter_party_role_id)&.id
      # final_receiver_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.final_receiver_party_role_id)&.id
      final_receiver_label = @repo.find(:party_roles, MasterfilesApp::PartyRepo, @form_object.final_receiver_party_role_id)&.id
      # final_destination_label = MasterfilesApp::DestinationRepo.new.find_destination_city(@form_object.final_destination_id)&.city_name
      final_destination_label = @repo.find(:destination_cities, MasterfilesApp::DestinationRepo, @form_object.final_destination_id)&.city_name
      # pol_voyage_port_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port(@form_object.pol_voyage_port_id)&.id
      pol_voyage_port_label = @repo.find(:voyage_ports, FinishedGoodsApp::VoyagePortFlat, @form_object.pol_voyage_port_id)&.port_code
      # pod_voyage_port_label = FinishedGoodsApp::VoyagePortRepo.new.find_voyage_port(@form_object.pod_voyage_port_id)&.id
      pod_voyage_port_label = @repo.find(:voyage_ports, FinishedGoodsApp::VoyagePortFlat, @form_object.pod_voyage_port_id)&.port_code
      fields[:depot__id] = { renderer: :label, with_value: depot_label, caption: 'Depot' }
      fields[:customer_party_role_id] = { renderer: :label, with_value: customer_label, caption: 'Customer' }
      fields[:consignee_party_role_id] = { renderer: :label, with_value: consignee_label, caption: 'Consignee' }
      fields[:billing_client_party_role_id] = { renderer: :label, with_value: billing_client_label, caption: 'Billing Client' }
      fields[:exporter_party_role_id] = { renderer: :label, with_value: exporter_label, caption: 'Exporter' }
      fields[:final_receiver_party_role_id] = { renderer: :label, with_value: final_receiver_label, caption: 'Final Receiver' }
      fields[:final_destination_id] = { renderer: :label, with_value: final_destination_label, caption: 'Final Destination' }
      fields[:pol_voyage_port_id] = { renderer: :label, with_value: pol_voyage_port_label, caption: 'POL Voyage Port' }
      fields[:pod_voyage_port_id] = { renderer: :label, with_value: pod_voyage_port_label, caption: 'POD Voyage Port' }
      fields[:order_number] = { renderer: :label }
      fields[:edi_file_name] = { renderer: :label }
      fields[:customer_order_number] = { renderer: :label }
      fields[:customer_reference] = { renderer: :label }
      fields[:exporter_certificate_code] = { renderer: :label }
      fields[:shipped_date] = { renderer: :label }
      fields[:shipped] = { renderer: :label, as_boolean: true }
      fields[:transfer_load] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    # def set_approve_fields
    #   set_show_fields
    #   fields[:approve_action] = { renderer: :select, options: [%w[Approve a], %w[Reject r]], required: true }
    #   fields[:reject_reason] = { renderer: :textarea, disabled: true }
    # end

    # def set_complete_fields
    #   set_show_fields
    #   user_repo = DevelopmentApp::UserRepo.new
    #   fields[:to] = { renderer: :select, options: user_repo.email_addresses(user_email_group: AppConst::EMAIL_GROUP_LOAD_APPROVERS), caption: 'Email address of person to notify', required: true }
    # end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        depot_id: { renderer: :select, options: MasterfilesApp::DestinationRepo.new.for_select_destination_depots, caption: 'Depot', required: true },
        customer_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_CUSTOMER), caption: 'Customer', required: true },
        consignee_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_CONSIGNEE), caption: 'Consignee', required: true },
        billing_client_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_BILLING_CLIENT), caption: 'Billing Client', required: true },
        exporter_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_EXPORTER), caption: 'Exporter', required: true },
        final_receiver_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_FINAL_RECEIVER), caption: 'Final Receiver', required: true },
        final_destination_id: { renderer: :select, options: MasterfilesApp::DestinationRepo.new.for_select_destination_cities, caption: 'Final Destination', required: true },
        pol_voyage_port_id: { renderer: :select, options: FinishedGoodsApp::VoyagePortRepo.new.for_select_voyage_ports, caption: 'POL Voyage Port', required: true },
        pod_voyage_port_id: { renderer: :select, options: FinishedGoodsApp::VoyagePortRepo.new.for_select_voyage_ports, caption: 'POD Voyage Port', required: true },
        order_number: {},
        edi_file_name: {},
        customer_order_number: {},
        customer_reference: {},
        exporter_certificate_code: {},
        shipped_date: { renderer: :datetime },
        shipped: { renderer: :checkbox },
        transfer_load: { renderer: :checkbox }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_load(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(depot_id: nil,
                                    customer_party_role_id: nil,
                                    consignee_party_role_id: nil,
                                    billing_client_party_role_id: nil,
                                    exporter_party_role_id: nil,
                                    final_receiver_party_role_id: nil,
                                    final_destination_id: nil,
                                    pol_voyage_port_id: nil,
                                    pod_voyage_port_id: nil,
                                    order_number: nil,
                                    edi_file_name: nil,
                                    customer_order_number: nil,
                                    customer_reference: nil,
                                    exporter_certificate_code: nil,
                                    shipped_date: DateTime.now,
                                    shipped: nil,
                                    transfer_load: nil)
    end

    # private

    # def add_approve_behaviours
    #   behaviours do |behaviour|
    #     behaviour.enable :reject_reason, when: :approve_action, changes_to: ['r']
    #   end
    # end
  end
end
