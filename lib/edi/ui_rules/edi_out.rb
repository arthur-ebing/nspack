# frozen_string_literal: true

module UiRules
  class EdiOutRule < Base
    def generate_rules
      @repo = EdiApp::EdiOutRepo.new
      make_form_object
      apply_form_values
      add_rules
      common_values_for_fields common_fields

      add_behaviours

      form_name 'edi_out_rule'
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      fields = {
        flow_type: { renderer: :select, options: AppConst::EDI_OUT_RULES_TEMPLATE.keys, caption: 'Flow Type', required: true, prompt: true },
        destination_type: { renderer: :select, options: [], caption: 'Destination Type', hide_on_load: rules[:is_ps_screen], required: false, prompt: true },
        depot_id: { renderer: :select, options: [], caption: 'Depot', hide_on_load: rules[:hide_depot_id], required: false, prompt: true },
        role_id: { renderer: :select, options: [], caption: 'Role', hide_on_load: rules[:is_depot_screen], required: false, prompt: true },
        party_role_id: { renderer: :select, options: [], caption: 'Party Role', hide_on_load: rules[:is_depot_screen], required: false, prompt: true },
        hub_address: {},
        directory_keys: { renderer: :multi, options: @repo.for_select_directory_keys, selected: @form_object.directory_keys, caption: 'Targets', required: true  }
      }

      fields[:destination_type][:options] = AppConst::DESTINATION_TYPES if rules[:is_po_screen]
      fields[:depot_id][:options] = MasterfilesApp::DepotRepo.new.for_select_depots if rules[:is_depot_screen]
      fields[:role_id][:options] = AppConst::EDI_OUT_RULES_TEMPLATE[@form_object.flow_type][:roles].to_a if rules[:is_po_party_role_screen] || rules[:is_ps_screen]
      fields[:party_role_id][:options] = MasterfilesApp::PartyRepo.new.for_select_party_roles_org_code(@form_object.role_id) unless @form_object.role_id.nil_or_empty?

      fields
    end

    def make_form_object # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      make_new_form_object && return if @mode == :new

      @form_object = OpenStruct.new(@repo.find_edi_out_rule(@options[:id]).to_h)
      @form_object[:destination_type] = AppConst::DEPOT_DESTINATION_TYPE unless @form_object.depot_id.nil_or_empty?
      @form_object[:destination_type] =  AppConst::PARTY_ROLE_DESTINATION_TYPE if @form_object.flow_type == AppConst::EDI_FLOW_PO && !@form_object.party_role_id.nil_or_empty?
      @form_object[:role_id] = MasterfilesApp::PartyRepo.new.find_role_by_party_role(@form_object.party_role_id)[:name] unless @form_object.party_role_id.nil_or_empty?
    end

    def make_new_form_object
      @form_object = OpenStruct.new(flow_type: nil,
                                    destination_type: nil,
                                    depot_id: nil,
                                    role_id: nil,
                                    party_role_id: nil,
                                    hub_address: nil,
                                    directory_keys: [])
    end

    private

    def add_rules # rubocop:disable Metrics/AbcSize
      rules[:is_po_party_role_screen] = (@form_object.flow_type == AppConst::EDI_FLOW_PO) && (@form_object.destination_type == AppConst::PARTY_ROLE_DESTINATION_TYPE)
      rules[:is_ps_screen] = @form_object.flow_type == AppConst::EDI_FLOW_PS
      rules[:hide_depot_id] = rules[:is_ps_screen] || rules[:is_po_party_role_screen]
      rules[:is_po_screen] = @form_object.flow_type == AppConst::EDI_FLOW_PO
      rules[:is_depot_screen] = (@form_object.flow_type == AppConst::EDI_FLOW_PO) && (@form_object.destination_type == AppConst::DEPOT_DESTINATION_TYPE)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :flow_type, notify: [{ url: '/edi/config/flow_type_changed' }]
        behaviour.dropdown_change :destination_type, notify: [{ url: '/edi/config/destination_type_changed' }]
        behaviour.dropdown_change :role_id, notify: [{ url: '/edi/config/role_id_changed' }]
      end
    end
  end
end
