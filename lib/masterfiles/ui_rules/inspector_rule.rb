# frozen_string_literal: true

module UiRules
  class InspectorRule < Base
    def generate_rules
      @repo = MasterfilesApp::InspectorRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'inspector'
    end

    def set_show_fields
      inspector_party_name = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.inspector_party_role_id)&.party_name
      fields[:inspector_party_role_id] = { renderer: :label,
                                           with_value: inspector_party_name,
                                           caption: 'Inspector' }
      fields[:tablet_ip_address] = { renderer: :label,
                                     caption: 'Tablet IP Address' }
      fields[:tablet_port_number] = { renderer: :label,
                                      caption: 'Tablet Port Number' }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      {
        inspector_party_role_id: { renderer: :select,
                                   options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_INSPECTOR),
                                   disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_INSPECTOR),
                                   caption: 'Inspector',
                                   required: true },
        tablet_ip_address: { caption: 'Tablet IP Address' },
        tablet_port_number: { caption: 'Tablet Port Number' }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_inspector(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspector_party_role_id: nil,
                                    tablet_ip_address: nil,
                                    tablet_port_number: nil)
    end
  end
end
