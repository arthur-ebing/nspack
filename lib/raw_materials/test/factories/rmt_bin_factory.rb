# frozen_string_literal: true

module RawMaterialsApp
  module RmtBinFactory
    def create_rmt_bin(opts = {}) # rubocop:disable Metrics/AbcSize
      id = get_available_factory_record(:rmt_bins, opts)
      return id unless id.nil?

      opts[:rmt_delivery_id] ||= create_rmt_delivery
      opts[:rmt_class_id] ||= create_rmt_class
      opts[:rmt_material_owner_party_role_id] ||= create_party_role(party_type: 'O', name: AppConst::ROLE_IMPLEMENTATION_OWNER)
      opts[:season_id] ||= create_season
      opts[:farm_id] ||= create_farm
      opts[:puc_id] ||= create_puc
      opts[:orchard_id] ||= create_orchard
      opts[:cultivar_id] ||= create_cultivar
      opts[:rmt_container_type_id] ||= create_rmt_container_type
      opts[:rmt_container_material_type_id] ||= create_rmt_container_material_type
      opts[:cultivar_group_id] ||= create_cultivar_group
      opts[:location_id] ||= create_location
      opts[:production_run_rebin_id] ||= create_production_run
      opts[:production_run_tipped_id] ||= create_production_run

      default = {
        exit_ref: Faker::Lorem.word,
        qty_bins: Faker::Number.number(digits: 4),
        bin_asset_number: Faker::Lorem.word,
        tipped_asset_number: Faker::Lorem.word,
        rmt_inner_container_type_id: Faker::Number.number(digits: 4),
        rmt_inner_container_material_id: Faker::Number.number(digits: 4),
        qty_inner_bins: Faker::Number.number(digits: 4),
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
        scrapped_at: '2010-01-01 12:00',
        scrapped_rmt_delivery_id: Faker::Number.number(digits: 4)
      }
      DB[:rmt_bins].insert(default.merge(opts))
    end

    def create_rmt_class(opts = {})
      id = get_available_factory_record(:rmt_classes, opts)
      return id unless id.nil?

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

    def create_rmt_size(opts = {})
      id = get_available_factory_record(:rmt_sizes, opts)
      return id unless id.nil?

      default = {
        size_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word
      }
      DB[:rmt_sizes].insert(default.merge(opts))
    end

    def create_assignment(opts = {})
      id = get_available_factory_record(:location_assignments, opts)
      return id unless id.nil?

      default = {
        assignment_code: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:location_assignments].insert(default.merge(opts))
    end

    def create_storage_type(opts = {})
      id = get_available_factory_record(:location_storage_types, opts)
      return id unless id.nil?

      default = {
        storage_type_code: Faker::Lorem.word,
        location_short_code_prefix: Faker::Lorem.word
      }
      DB[:location_storage_types].insert(default.merge(opts))
    end
  end
end
