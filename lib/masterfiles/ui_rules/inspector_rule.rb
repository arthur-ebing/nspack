# frozen_string_literal: true

module UiRules
  class InspectorRule < Base
    def generate_rules
      @repo = MasterfilesApp::InspectorRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'inspector'
    end

    def set_show_fields
      fields[:inspector] = { renderer: :label }
      fields[:inspector_code] = { renderer: :label }
      fields[:tablet_ip_address] = { renderer: :label,
                                     caption: 'Tablet IP Address' }
      fields[:tablet_port_number] = { renderer: :label,
                                      caption: 'Tablet Port Number' }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields
      {
        inspector: { caption: 'Inspector',
                     renderer: :label,
                     initially_visible: @mode == :edit },
        inspector_party_role_id: { hide_on_load: true },
        inspector_code: { caption: 'Inspector Code',
                          force_uppercase: true,
                          required: true },
        tablet_ip_address: { caption: 'Tablet IP Address',
                             required: true },
        tablet_port_number: { renderer: :integer,
                              caption: 'Tablet Port Number',
                              required: true },
        # Person
        title: { required: true },
        surname: { required: true },
        first_name: { required: true }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_inspector(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspector_code: nil,
                                    inspector_party_role_id: 'Create New Person',
                                    tablet_ip_address: nil,
                                    tablet_port_number: nil)
    end
  end
end
