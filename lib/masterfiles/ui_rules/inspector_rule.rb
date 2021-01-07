# frozen_string_literal: true

module UiRules
  class InspectorRule < Base
    def generate_rules
      @repo = MasterfilesApp::InspectorRepo.new
      @party_repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields
      add_approve_behaviours if %i[new].include? @mode

      set_show_fields if %i[show reopen].include? @mode

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
      party_role_options = @party_repo.for_select_party_roles_exclude(AppConst::ROLE_INSPECTOR, where: { organization_id: nil })
      party_role_options << ['Create New Person', 'P']
      { inspector: { caption: 'Inspector',
                     renderer: :label,
                     hide_on_load: @mode == :new },
        party_role_id: { caption: 'Inspector',
                         renderer: :select,
                         options: party_role_options,
                         sort_items: false,
                         searchable: true,
                         prompt: true,
                         hide_on_load: @mode == :edit,
                         required: true },
        inspector_code: { caption: 'Inspector Code',
                          force_uppercase: true,
                          required: true },
        tablet_ip_address: { caption: 'Tablet IP Address',
                             required: true },
        tablet_port_number: { renderer: :integer,
                              caption: 'Tablet Port Number',
                              required: true },
        # Person
        title: { hide_on_load: true },
        surname: { hide_on_load: true },
        first_name: { hide_on_load: true },
        vat_number: { hide_on_load: true } }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_inspector(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(inspector_code: nil,
                                    tablet_ip_address: nil,
                                    tablet_port_number: nil)
    end

    private

    def add_approve_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :party_role_id, notify: [{ url: '/masterfiles/quality/inspectors/inspector_party_role_changed' }]
      end
    end
  end
end
