# frozen_string_literal: true

module UiRules
  class InspectorRule < Base
    def generate_rules
      @repo = MasterfilesApp::InspectorRepo.new
      make_form_object
      apply_form_values

      case @mode
      when :edit
        common_values_for_fields common_fields_edit
      when :new
        common_values_for_fields common_fields
      else
        set_show_fields
      end

      form_name 'inspector'
    end

    def set_show_fields
      fields[:title] = { renderer: :label }
      fields[:first_name] = { renderer: :label }
      fields[:surname] = { renderer: :label }
      fields[:role_ids] = { renderer: :hidden }
      fields[:inspector_code] = { renderer: :label }
      fields[:tablet_ip_address] = { renderer: :label,
                                     caption: 'Tablet IP Address' }
      fields[:tablet_port_number] = { renderer: :label,
                                      caption: 'Tablet Port Number' }
      fields[:active] = { renderer: :label,
                          as_boolean: true }
    end

    def common_fields_edit
      {
        inspector_party_role_id: { renderer: :select,
                                   options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_INSPECTOR),
                                   disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_INSPECTOR),
                                   caption: 'Inspector' },
        inspector_code: { caption: 'Inspector Code',
                          force_uppercase: true,
                          required: true },
        tablet_ip_address: { caption: 'Tablet IP Address',
                             required: true },
        tablet_port_number: { caption: 'Tablet Port Number',
                              required: true }
      }
    end

    def common_fields
      {
        inspector_party_role_id: { renderer: :select,
                                   options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_INSPECTOR),
                                   disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_INSPECTOR),
                                   caption: 'Inspector',
                                   hide_on_load: true },
        surname: { required: true },
        first_name: { required: true },
        title: { required: true },
        vat_number: { hide_on_load: true },
        role_ids: { renderer: :multi,
                    options: @form_object.role_ids,
                    selected: @form_object.role_ids,
                    hide_on_load: true },
        inspector_code: { caption: 'Inspector Code',
                          force_uppercase: true,
                          required: true },
        tablet_ip_address: { caption: 'Tablet IP Address',
                             required: true },
        tablet_port_number: { caption: 'Tablet Port Number',
                              required: true }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_inspector_flat(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(surname: nil,
                                    first_name: nil,
                                    title: nil,
                                    vat_number: nil,
                                    role_ids: [@repo.get_with_args(:roles, :id, name: AppConst::ROLE_INSPECTOR)],
                                    inspector_party_role_id: nil,
                                    inspector_code: nil,
                                    tablet_ip_address: nil,
                                    tablet_port_number: nil)
    end
  end
end
