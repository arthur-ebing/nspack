# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module RawMaterialsApp
  module RmtBinFactory # rubocop:disable ModuleLength
    def create_rmt_bin(opts = {}) # rubocop:disable Metrics/AbcSize
      rmt_delivery_id = create_rmt_delivery
      rmt_class_id = create_rmt_class
      rmt_container_material_owner_id = create_rmt_container_material_owner
      season_id = create_season
      farm_id = create_farm
      puc_id = create_puc
      orchard_id = create_orchard
      cultivar_id = create_cultivar
      rmt_container_type_id = create_rmt_container_type
      rmt_container_material_type_id = create_rmt_container_material_type
      cultivar_group_id = create_cultivar_group

      default = {
        rmt_delivery_id: rmt_delivery_id,
        season_id: season_id,
        cultivar_id: cultivar_id,
        orchard_id: orchard_id,
        farm_id: farm_id,
        rmt_class_id: rmt_class_id,
        rmt_container_material_owner_id: rmt_container_material_owner_id,
        rmt_container_type_id: rmt_container_type_id,
        rmt_container_material_type_id: rmt_container_material_type_id,
        cultivar_group_id: cultivar_group_id,
        puc_id: puc_id,
        status: Faker::Lorem.unique.word,
        exit_ref: Faker::Lorem.word,
        qty_bins: Faker::Number.number(4),
        bin_asset_number: Faker::Number.number(4),
        tipped_asset_number: Faker::Number.number(4),
        rmt_inner_container_type_id: Faker::Number.number(4),
        rmt_inner_container_material_id: Faker::Number.number(4),
        qty_inner_bins: Faker::Number.number(4),
        production_run_rebin_id: Faker::Number.number(4),
        production_run_tipped_id: Faker::Number.number(4),
        production_run_tipping_id: Faker::Number.number(4),
        bin_tipping_plant_resource_id: Faker::Number.number(4),
        bin_fullness: Faker::Lorem.word,
        nett_weight: Faker::Number.decimal,
        gross_weight: Faker::Number.decimal,
        active: true,
        bin_tipped: false,
        tipping: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        bin_received_date_time: '2010-01-01 12:00',
        bin_tipped_date_time: '2010-01-01 12:00',
        exit_ref_date_time: '2010-01-01 12:00',
        bin_tipping_started_date_time: '2010-01-01 12:00',
        rebin_created_at: '2010-01-01 12:00'
      }
      DB[:rmt_bins].insert(default.merge(opts))
    end

    def create_rmt_delivery(opts = {})
      orchard_id = create_orchard
      cultivar_id = create_cultivar
      rmt_delivery_destination_id = create_rmt_delivery_destination
      season_id = create_season
      farm_id = create_farm
      puc_id = create_puc

      default = {
        orchard_id: orchard_id,
        cultivar_id: cultivar_id,
        rmt_delivery_destination_id: rmt_delivery_destination_id,
        season_id: season_id,
        farm_id: farm_id,
        puc_id: puc_id,
        truck_registration_number: Faker::Lorem.word,
        qty_damaged_bins: Faker::Number.number(4),
        qty_empty_bins: Faker::Number.number(4),
        active: true,
        delivery_tipped: false,
        date_picked: '2010-01-01',
        date_delivered: '2010-01-01 12:00',
        tipping_complete_date_time: '2010-01-01 12:00',
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_deliveries].insert(default.merge(opts))
    end

    def create_orchard(opts = {})
      farm_id = create_farm
      puc_id = create_puc

      default = {
        farm_id: farm_id,
        puc_id: puc_id,
        orchard_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        cultivar_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:orchards].insert(default.merge(opts))
    end

    def create_farm(opts = {})
      party_role_id = create_party_role[:id]
      production_region_id = create_production_region
      farm_group_id = create_farm_group

      default = {
        owner_party_role_id: party_role_id,
        pdn_region_id: production_region_id,
        farm_group_id: farm_group_id,
        farm_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:farms].insert(default.merge(opts))
    end

    def create_production_region(opts = {})
      default = {
        production_region_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:production_regions].insert(default.merge(opts))
    end

    def create_farm_group(opts = {})
      party_role_id = create_party_role('O', 'FARM_OWNER')[:id]
      default = {
        owner_party_role_id: party_role_id,
        farm_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:farm_groups].insert(default.merge(opts))
    end

    def create_puc(opts = {})
      default = {
        puc_code: Faker::Lorem.unique.word,
        gap_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:pucs].insert(default.merge(opts))
    end

    def create_cultivar(opts = {})
      commodity_id = create_commodity
      cultivar_group_id = create_cultivar_group

      default = {
        commodity_id: commodity_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_name: Faker::Lorem.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:cultivars].insert(default.merge(opts))
    end

    def create_commodity(opts = {})
      commodity_group_id = create_commodity_group

      default = {
        commodity_group_id: commodity_group_id,
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        hs_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:commodities].insert(default.merge(opts))
    end

    def create_commodity_group(opts = {})
      default = {
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:commodity_groups].insert(default.merge(opts))
    end

    def create_cultivar_group(opts = {})
      default = {
        cultivar_group_code: Faker::Lorem.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:cultivar_groups].insert(default.merge(opts))
    end

    def create_rmt_delivery_destination(opts = {})
      default = {
        delivery_destination_code: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_delivery_destinations].insert(default.merge(opts))
    end

    def create_season(opts = {})
      season_group_id = create_season_group
      commodity_id = create_commodity

      default = {
        season_group_id: season_group_id,
        commodity_id: commodity_id,
        season_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        start_date: '2010-01-01 12:00',
        end_date: '2010-01-01 12:00',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        season_year: Faker::Number.number(4)
      }
      DB[:seasons].insert(default.merge(opts))
    end

    def create_season_group(opts = {})
      default = {
        season_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_group_year: Faker::Number.number(4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:season_groups].insert(default.merge(opts))
    end

    def create_rmt_class(opts = {})
      default = {
        rmt_class_code: Faker::Lorem.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        grade: Faker::Lorem.word
      }
      DB[:rmt_classes].insert(default.merge(opts))
    end

    def create_rmt_container_material_owner(opts = {})
      rmt_container_material_type_id = create_rmt_container_material_type
      rmt_material_owner_party_role_id = create_party_role[:id]

      default = {
        rmt_container_material_type_id: rmt_container_material_type_id,
        rmt_material_owner_party_role_id: rmt_material_owner_party_role_id
      }
      DB[:rmt_container_material_owners].insert(default.merge(opts))
    end

    def create_rmt_container_material_type(opts = {})
      rmt_container_type_id = create_rmt_container_type

      default = {
        rmt_container_type_id: rmt_container_type_id,
        container_material_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_container_material_types].insert(default.merge(opts))
    end

    def create_rmt_container_type(opts = {})
      default = {
        container_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:rmt_container_types].insert(default.merge(opts))
    end
  end
end
