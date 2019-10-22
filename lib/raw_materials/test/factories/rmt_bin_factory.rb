# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module RawMaterialsApp
  module RmtBinFactory
    def create_rmt_bin(opts = {}) # rubocop:disable Metrics/AbcSize
      rmt_delivery_id = create_rmt_delivery
      rmt_class_id = create_rmt_class
      rmt_material_owner_party_role_id = create_party_role('O')[:id]
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
        rmt_material_owner_party_role_id: rmt_material_owner_party_role_id,
        rmt_container_type_id: rmt_container_type_id,
        rmt_container_material_type_id: rmt_container_material_type_id,
        cultivar_group_id: cultivar_group_id,
        puc_id: puc_id,
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
        rebin_created_at: '2010-01-01 12:00',
        scrapped: false,
        scrapped_at: '2010-01-01 12:00'
      }
      DB[:rmt_bins].insert(default.merge(opts))
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

    # def create_rmt_container_material_owner(opts = {})
    #   rmt_container_material_type_id = create_rmt_container_material_type
    #   rmt_material_owner_party_role_id = create_party_role[:id]
    #
    #   default = {
    #     rmt_container_material_type_id: rmt_container_material_type_id,
    #     rmt_material_owner_party_role_id: rmt_material_owner_party_role_id
    #   }
    #   DB[:rmt_container_material_owners].insert(default.merge(opts))
    # end
  end
end
