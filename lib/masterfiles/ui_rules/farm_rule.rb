# frozen_string_literal: true

module UiRules
  class FarmRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      # add_behaviours if @options[:id]

      form_name 'farm'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      owner_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.owner_party_role_id)&.party_name
      pdn_region_id_label = @repo.find_hash(:production_regions, @form_object.pdn_region_id)[:production_region_code]
      farm_group_id_label = @repo.find_farm_group(@form_object.farm_group_id)&.farm_group_code
      puc_id_label = @repo.find_puc(@form_object.puc_id)&.puc_code
      fields[:owner_party_role_id] = { renderer: :label,
                                       with_value: owner_party_role_id_label,
                                       caption: 'Farm Owner' }
      fields[:pdn_region_id] = { renderer: :label,
                                 with_value: pdn_region_id_label,
                                 caption: 'Pdn Region' }
      fields[:farm_group_id] = { renderer: :label,
                                 with_value: farm_group_id_label,
                                 caption: 'Farm Group' }
      fields[:puc_id] = { renderer: :label,
                          with_value: puc_id_label,
                          caption: 'Primary Puc' }
      fields[:farm_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:pucs] = { renderer: :list, items: farm_puc_codes }
      fields[:orchards] = { renderer: :list, items: farm_orchard_codes }
    end

    def common_fields
      farm_pucs = @options[:id] ? @repo.selected_farm_pucs(@options[:id]) : @repo.select_unallocated_pucs
      {
        owner_party_role_id: { renderer: :select,
                               options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_FARM_OWNER),
                               required: true,
                               caption: 'Farm Owner' },
        pdn_region_id: { renderer: :select,
                         options: @repo.for_select_production_regions,
                         disabled_options: @repo.for_select_inactive_production_regions,
                         required: true },
        farm_group_id: { renderer: :select,
                         options: @repo.for_select_farm_groups,
                         disabled_options: @repo.for_select_inactive_farm_groups,
                         prompt: 'Select Farm Group' },
        farm_code: { required: true },
        description: {},
        active: { renderer: :checkbox },
        puc_id: { renderer: :select,
                  options: farm_pucs,
                  disabled_options: @repo.for_select_inactive_pucs,
                  caption: 'Primary Puc',
                  required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_farm(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(owner_party_role_id: nil,
                                    pdn_region_id: nil,
                                    farm_group_id: nil,
                                    farm_code: nil,
                                    description: nil,
                                    active: true,
                                    puc_id: nil)
    end

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :owner_party_role_id, notify: [{ url: "/masterfiles/farms/farms/#{@options[:id]}/owner_party_role_changed" }]
      end
    end

    def farm_puc_codes
      @repo.find_farm_puc_codes(@options[:id])
    end

    def farm_orchard_codes
      @repo.find_farm_orchard_codes(@options[:id])
    end
  end
end
