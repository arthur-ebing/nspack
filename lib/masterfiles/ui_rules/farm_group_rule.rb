# frozen_string_literal: true

module UiRules
  class FarmGroupRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'farm_group'
    end

    def set_show_fields
      owner_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.owner_party_role_id)&.party_name
      fields[:owner_party_role_id] = { renderer: :label, with_value: owner_party_role_id_label, caption: 'Owner Party Role' }
      fields[:farm_group_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:farms] = { renderer: :list, items: farm_group_farms }
    end

    def common_fields
      {
        owner_party_role_id: { renderer: :select,
                               options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_FARM_OWNER),
                               required: true },
        farm_group_code: { required: true },
        description: {},
        active: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_farm_group(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(owner_party_role_id: nil,
                                    farm_group_code: nil,
                                    description: nil,
                                    active: true)
    end

    def farm_group_farms
      @repo.find_farm_group_farm_codes(@options[:id])
    end
  end
end
