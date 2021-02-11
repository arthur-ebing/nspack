# frozen_string_literal: true

module RawMaterialsApp
  module RmtBinFactory # rubocop:disable Metrics/ModuleLength
    def create_rmt_bin(opts = {}) # rubocop:disable Metrics/AbcSize
      rmt_delivery_id = create_rmt_delivery
      rmt_class_id = create_rmt_class
      rmt_material_owner_party_role_id = create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      season_id = create_season
      farm_id = create_farm
      puc_id = create_puc
      orchard_id = create_orchard
      cultivar_id = create_cultivar
      rmt_container_type_id = create_rmt_container_type
      rmt_container_material_type_id = create_rmt_container_material_type
      cultivar_group_id = create_cultivar_group
      location_id = create_location
      production_run_rebin_id = create_production_run
      production_run_tipped_id = create_production_run

      default = {
        rmt_delivery_id: rmt_delivery_id,
        season_id: season_id,
        cultivar_id: cultivar_id,
        orchard_id: orchard_id,
        farm_id: farm_id,
        rmt_class_id: rmt_class_id,
        rmt_material_owner_party_role_id: rmt_material_owner_party_role_id,
        rmt_container_type_id: rmt_container_type_id,
        rmt_container_material_type_id: rmt_container_material_type_id,
        cultivar_group_id: cultivar_group_id,
        puc_id: puc_id,
        location_id: location_id,
        exit_ref: Faker::Lorem.word,
        qty_bins: Faker::Number.number(digits: 4),
        bin_asset_number: Faker::Lorem.word,
        tipped_asset_number: Faker::Lorem.word,
        rmt_inner_container_type_id: Faker::Number.number(digits: 4),
        rmt_inner_container_material_id: Faker::Number.number(digits: 4),
        qty_inner_bins: Faker::Number.number(digits: 4),
        production_run_rebin_id: production_run_rebin_id,
        production_run_tipped_id: production_run_tipped_id,
        bin_tipping_plant_resource_id: Faker::Number.number(digits: 4),
        bin_fullness: Faker::Lorem.word,
        nett_weight: Faker::Number.decimal,
        gross_weight: Faker::Number.decimal,
        active: true,
        bin_tipped: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        bin_received_date_time: '2010-01-01 12:00',
        bin_tipped_date_time: '2010-01-01 12:00',
        exit_ref_date_time: '2010-01-01 12:00',
        rebin_created_at: '2010-01-01 12:00',
        scrapped: false,
        scrapped_at: '2010-01-01 12:00'
      }
      DB[:rmt_bins].insert(default.merge(opts))
    end

    def create_rmt_class(opts = {})
      default = {
        rmt_class_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        grade: Faker::Lorem.word
      }
      DB[:rmt_classes].insert(default.merge(opts))
    end

    def create_location_type(opts = {})
      default = {
        location_type_code: Faker::Lorem.word,
        short_code: Faker::Lorem.word,
        can_be_moved: false,
        hierarchical: false
      }
      DB[:location_types].insert(default.merge(opts))
    end

    def create_assignment(opts = {})
      default = {
        assignment_code: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:location_assignments].insert(default.merge(opts))
    end

    def create_storage_type(opts = {})
      default = {
        storage_type_code: Faker::Lorem.word,
        location_short_code_prefix: Faker::Lorem.word
      }
      DB[:location_storage_types].insert(default.merge(opts))
    end

    def create_location_storage_definition(opts = {})
      default = {
        storage_definition_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        storage_definition_format: Faker::Lorem.word,
        storage_definition_description: Faker::Lorem.word
      }
      DB[:location_storage_definitions].insert(default.merge(opts))
    end

    def create_location(opts = {})
      location_type_id = create_location_type
      primary_storage_type_id = create_storage_type
      primary_assignment_id = create_assignment
      location_storage_definition_id = create_location_storage_definition
      default = {
        primary_storage_type_id: primary_storage_type_id,
        location_type_id: location_type_id,
        primary_assignment_id: primary_assignment_id,
        location_description: Faker::Lorem.word,
        active: true,
        has_single_container: false,
        virtual_location: false,
        consumption_area: false,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        location_long_code: Faker::Lorem.word,
        location_short_code: Faker::Lorem.word,
        can_be_moved: false,
        print_code: Faker::Lorem.word,
        location_storage_definition_id: location_storage_definition_id,
        can_store_stock: false,
        units_in_location: 0
      }
      DB[:locations].insert(default.merge(opts))
    end

    def create_rmt_container_material_owner(opts = {})
      rmt_container_material_type_id = create_rmt_container_material_type
      rmt_material_owner_party_role_id = create_party_role(party_type: 'P', name: AppConst::ROLE_RMT_BIN_OWNER)

      default = {
        rmt_container_material_type_id: rmt_container_material_type_id,
        rmt_material_owner_party_role_id: rmt_material_owner_party_role_id
      }
      DB[:rmt_container_material_owners].insert(default.merge(opts))
    end
  end
end
