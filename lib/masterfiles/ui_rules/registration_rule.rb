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
      fields[:party_role_id] = { renderer: :label, caption: 'Role',
                                 with_value: @form_object.role_name }
      fields[:registration_type] = { renderer: :label }
      fields[:registration_code] = { renderer: :label }
    end

    def common_fields
      {
        party_role_id: { renderer: :select,
                         options: @repo.for_select_roles_for_party_roles(
                           where: { party_id: @form_object.party_id }
                         ),
                         disabled_options: @repo.for_select_inactive_roles_for_party_roles,
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
                                    party_id: @options[:party_id],
                                    registration_type: nil,
                                    registration_code: nil)
    end
  end
end
