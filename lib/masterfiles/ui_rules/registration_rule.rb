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
      options = []
      role_ids = @repo.select_values(:party_roles, :role_id, party_id: @form_object.party_id)
      roles = @repo.select_values(:roles, :name, id: role_ids)
      AppConst::PARTY_ROLE_REGISTRATION_TYPES.each do |registration_type, role|
        next unless roles.include? role

        options << ["#{role} - #{registration_type}", registration_type]
      end

      {
        party_id: { renderer: :hidden },
        registration_type: { renderer: :select,
                             options: options,
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
