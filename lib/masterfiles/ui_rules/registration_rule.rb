# frozen_string_literal: true

module UiRules
  class RegistrationRule < Base
    def generate_rules
      @repo = MasterfilesApp::PartyRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'registration'
    end

    def set_show_fields
      party_role_id_label = @repo.find_party_role(@form_object.party_role_id)&.role_name
      fields[:party_role_id] = { renderer: :label,
                                 with_value: party_role_id_label,
                                 caption: 'Role' }
      fields[:registration_type] = { renderer: :label }
      fields[:registration_code] = { renderer: :label }
    end

    def common_fields
      party_role_options = if @mode == :new
                             @repo.for_select_party_roles_role(where: { party_id: @options[:party_id] })
                           else
                             @repo.for_select_party_roles_role(where: { party_role_id: @form_object.party_role_id })
                           end
      {
        party_role_id: { renderer: :select,
                         options: party_role_options,
                         disabled_options: @repo.for_select_inactive_party_roles_role,
                         caption: 'Role',
                         required: true },
        registration_type: { renderer: :select,
                             options: AppConst::PARTY_ROLE_REGISTRATION_TYPES,
                             required: true },
        registration_code: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_registration(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(party_role_id: nil,
                                    registration_type: nil,
                                    registration_code: nil)
    end
  end
end
