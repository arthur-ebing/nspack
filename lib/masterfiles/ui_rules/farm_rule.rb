# frozen_string_literal: true

module UiRules
  class FarmRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields if %i[new edit].include? @mode

      set_show_fields if %i[show].include? @mode

      form_name 'farm'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      owner_party_role_id_label = MasterfilesApp::PartyRepo.new.find_party_role(@form_object.owner_party_role_id)&.party_name
      pdn_region_id_label = @repo.find_hash(:production_regions, @form_object.pdn_region_id)[:production_region_code]
      farm_group_id_label = @repo.find_farm_group(@form_object.farm_group_id)&.farm_group_code
      location_id_label = @repo.get(:locations, :location_long_code, @form_object.location_id)
      fields[:owner_party_role_id] = { renderer: :label,
                                       with_value: owner_party_role_id_label,
                                       caption: 'Farm Owner' }
      fields[:pdn_region_id] = { renderer: :label,
                                 with_value: pdn_region_id_label,
                                 caption: 'PDN Region' }
      fields[:farm_group_id] = { renderer: :label,
                                 with_value: farm_group_id_label,
                                 caption: 'Farm Group' }
      fields[:farm_code] = { renderer: :label,
                             caption: 'Farm' }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:pucs] = { renderer: :list,
                        items: farm_puc_codes,
                        caption: 'PUCs' }
      fields[:orchards] = { renderer: :list,
                            items: list_orchards }
      fields[:location_id] = { renderer: :label,
                               with_value: location_id_label,
                               caption: 'Location',
                               invisible: !AppConst::CR_RMT.create_farm_location?  }
    end

    def common_fields
      {
        owner_party_role_id: { renderer: :select,
                               options: MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_FARM_OWNER),
                               required: true,
                               caption: 'Farm Owner' },
        pdn_region_id: { renderer: :select,
                         options: @repo.for_select_production_regions,
                         disabled_options: @repo.for_select_inactive_production_regions,
                         caption: 'PDN Region',
                         required: true },
        farm_group_id: { renderer: :select,
                         options: @repo.for_select_farm_groups,
                         disabled_options: @repo.for_select_inactive_farm_groups,
                         prompt: 'Select Farm Group' },
        puc_id: { renderer: :select,
                  options: @repo.for_select_pucs_with_farms,
                  disabled_options: @repo.for_select_inactive_pucs,
                  caption: 'PUC',
                  invisible: @mode != :new,
                  required: true },
        farm_code: { required: true },
        description: {},
        active: { renderer: :checkbox }
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
                                    puc_id: nil,
                                    location_id: nil)
    end

    private

    def add_behaviours
      behaviours do |behaviour|
        behaviour.dropdown_change :owner_party_role_id, notify: [{ url: "/masterfiles/farms/farms/#{@options[:id]}/owner_party_role_changed" }]
      end
    end

    def farm_puc_codes
      @repo.find_farm_puc_codes(@options[:id])
    end

    def list_orchards
      orchards = @repo.select_values_in_order(:orchards, %i[orchard_code description], where: { farm_id: @options[:id] }, order: :orchard_code)
      orchards.map { |orchard_code, description| ["#{orchard_code} - #{description}"] }
    end
  end
end
