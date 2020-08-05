# frozen_string_literal: true

module UiRules
  class EdiOutRule < Base
    def generate_rules
      @repo = EdiApp::EdiOutRepo.new
      make_form_object
      apply_form_values
      add_rules
      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      add_behaviours

      form_name 'edi_out_rule'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      @form_object.directory_keys = @repo.format_targets(@form_object.directory_keys)
      @form_object.active = @repo.load_config[:send_edi][@form_object.flow_type.downcase.to_sym]

      depot_id_label = @repo.find(:depots, MasterfilesApp::Depot, @form_object.depot_id)&.depot_code
      party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.party_role_id)&.party_name
      role_id_label = (MasterfilesApp::PartyRepo.new.find_role_by_party_role(@form_object.party_role_id) || {})[:name]
      fields[:flow_type] = { renderer: :label }
      fields[:depot_id] = { renderer: :label, with_value: depot_id_label, caption: 'Depot' } unless rules[:hide_depot_id]
      fields[:role_id] = { renderer: :label, with_value: role_id_label, caption: 'Role' } unless rules[:hide_role_id]
      fields[:party_role_id] = { renderer: :label, with_value: party_role_id_label, caption: 'Party Role' } unless rules[:hide_role_id]
      fields[:hub_address] = { renderer: :label }
      fields[:directory_keys] = { renderer: :list, caption: 'Targets', items: @form_object.directory_keys }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      fields = {
        flow_type: { renderer: :select, options: AppConst::EDI_OUT_RULES_TEMPLATE.keys, caption: 'Flow Type', required: true, prompt: true, min_charwidth: 30 },
        destination_type: { renderer: :select, options: [], caption: 'Destination Type', hide_on_load: rules[:hide_destination_type], required: false, prompt: true, min_charwidth: 30 },
        depot_id: { renderer: :select, options: [], caption: 'Depot', hide_on_load: rules[:hide_depot_id], required: false, prompt: true },
        role_id: { renderer: :select, options: [], caption: 'Role', hide_on_load: rules[:hide_role_id], required: false, prompt: true },
        party_role_id: { renderer: :select, options: [], caption: 'Party Role', hide_on_load: rules[:hide_role_id], required: false, prompt: true },
        hub_address: {},
        directory_keys: { renderer: :multi, options: @repo.for_select_directory_keys, selected: @form_object.directory_keys, caption: 'Targets', required: true  }
      }

      fields[:destination_type][:options] = AppConst::DESTINATION_TYPES unless rules[:hide_destination_type]
      fields[:depot_id][:options] = MasterfilesApp::DepotRepo.new.for_select_depots unless rules[:hide_depot_id]
      fields[:role_id][:options] = AppConst::EDI_OUT_RULES_TEMPLATE[@form_object.flow_type][:roles].to_a unless rules[:hide_role_id] || !@form_object.flow_type
      fields[:party_role_id][:options] = MasterfilesApp::PartyRepo.new.for_select_party_roles_org_code(@form_object.role_id) unless rules[:hide_role_id]

      fields
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = OpenStruct.new(@repo.find_edi_out_rule_flat(@options[:id]).to_h)
      @form_object[:destination_type] =  @form_object.depot_id.nil_or_empty? ? AppConst::PARTY_ROLE_DESTINATION_TYPE : AppConst::DEPOT_DESTINATION_TYPE
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

    def add_rules # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      rules[:hide_destination_type] = @form_object.flow_type && (destinations = @repo.destinations_for_flow(@form_object.flow_type)) && (destinations.size == 1 && destinations[0] == AppConst::PARTY_ROLE_DESTINATION_TYPE)
      rules[:hide_depot_id] = (@mode == :edit && @form_object.depot_id.nil_or_empty?) || @form_object.destination_type == AppConst::PARTY_ROLE_DESTINATION_TYPE || (!@form_object.flow_type.nil_or_empty? && !AppConst::EDI_OUT_RULES_TEMPLATE[@form_object.flow_type][:depot])
      rules[:hide_role_id] = (@mode == :edit && !@form_object.depot_id.nil_or_empty?) || @form_object.destination_type == AppConst::DEPOT_DESTINATION_TYPE
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :flow_type, notify: [{ url: '/edi/config/flow_type_changed' }]
        behaviour.dropdown_change :destination_type, notify: [{ url: '/edi/config/destination_type_changed', param_keys: %i[edi_out_rule_flow_type] }]
        behaviour.dropdown_change :role_id, notify: [{ url: '/edi/config/role_id_changed' }]
      end
    end
  end
end
