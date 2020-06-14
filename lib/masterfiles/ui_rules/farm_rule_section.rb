# frozen_string_literal: true

module UiRules
  class FarmSectionRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'farm_section'
    end

    def set_show_fields
      farm_manager_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.farm_manager_party_role_id)&.party_name
      fields[:farm_manager_party_role_id] = { renderer: :label, with_value: farm_manager_party_role_id_label, caption: 'Farm Manager' }
      fields[:farm_section_name] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:orchard_ids] = { renderer: :list, caption: 'Orchards', items: @repo.for_select_orchards(where: { id: @form_object.orchard_ids }) }
    end

    def common_fields
      {
        farm_section_name: { required: true },
        farm_manager_party_role_id: { renderer: :select, options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_FARM_MANAGER),
                                      disabled_options: MasterfilesApp::PartyRepo.new.for_select_inactive_party_roles(AppConst::ROLE_FARM_MANAGER),
                                      prompt: 'Select Farm Manager',
                                      caption: 'Farm Manager', required: true },
        description: {},
        orchard_ids: { renderer: :multi, options: @repo.for_select_orchards(where: { farm_id: @options[:farm_id], farm_section_id: nil }) + @repo.for_select_orchards(where: { id: @form_object.orchard_ids }), caption: 'Orchards', selected: @form_object.orchard_ids, required: true  }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_farm_section(@options[:id])
      @options[:farm_id] = @form_object.farm_id
    end

    def make_new_form_object
      @form_object = OpenStruct.new(farm_manager_party_role_id: nil,
                                    farm_section_name: nil,
                                    description: nil)
    end
  end
end
