# frozen_string_literal: true

module MasterfilesApp
  module FarmFactory
    def create_production_region(opts = {})
      id = get_available_factory_record(:production_regions, opts)
      return id unless id.nil?

      default = {
        production_region_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        inspection_region: Faker::Lorem.word
      }
      DB[:production_regions].insert(default.merge(opts))
    end

    def create_puc(opts = {})
      id = get_available_factory_record(:pucs, opts)
      return id unless id.nil?

      default = {
        puc_code: Faker::Lorem.unique.word,
        gap_code: Faker::Lorem.word,
        active: true,
        gap_code_valid_from: '2010-01-01 12:00',
        gap_code_valid_until: '2010-01-01 12:00'
      }
      DB[:pucs].insert(default.merge(opts))
    end

    def create_farm_group(opts = {})
      id = get_available_factory_record(:farm_groups, opts)
      return id unless id.nil?

      owner_party_role_id = create_party_role(name: AppConst::ROLE_FARM_OWNER)

      default = {
        owner_party_role_id: owner_party_role_id,
        farm_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:farm_groups].insert(default.merge(opts))
    end

    def create_farm(opts = {})
      id = get_available_factory_record(:farms, opts)
      return id unless id.nil?

      owner_party_role_id = create_party_role(name: AppConst::ROLE_FARM_OWNER)
      production_region_id = create_production_region
      farm_group_id = create_farm_group

      default = {
        owner_party_role_id: owner_party_role_id,
        pdn_region_id: production_region_id,
        farm_group_id: farm_group_id,
        farm_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true
      }
      DB[:farms].insert(default.merge(opts))
    end

    def create_farm_section(opts = {})
      id = get_available_factory_record(:farm_sections, opts)
      return id unless id.nil?

      party_role_id = create_party_role
      default = {
        farm_manager_party_role_id: party_role_id,
        farm_section_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word
      }
      DB[:farm_sections].insert(default.merge(opts))
    end

    def create_orchard(opts = {})
      id = get_available_factory_record(:orchards, opts)
      return id unless id.nil?

      farm_id = create_farm
      puc_id = create_puc
      cultivar_id = create_cultivar
      default = {
        farm_id: farm_id,
        orchard_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        cultivar_ids: "{#{cultivar_id}}",
        active: true,
        puc_id: puc_id
      }
      DB[:orchards].insert(default.merge(opts))
    end

    def create_registered_orchard(opts = {})
      id = get_available_factory_record(:registered_orchards, opts)
      return id unless id.nil?

      default = {
        orchard_code: Faker::Lorem.unique.word,
        cultivar_code: Faker::Lorem.word,
        puc_code: Faker::Lorem.word,
        description: Faker::Lorem.word,
        marketing_orchard: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:registered_orchards].insert(default.merge(opts))
    end
  end
end
