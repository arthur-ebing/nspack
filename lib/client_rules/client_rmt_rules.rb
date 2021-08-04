# frozen_string_literal: true

module Crossbeams
  class ClientRmtRules < BaseClientRules # rubocop:disable Metrics/ClassLength
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: [] },
      hl: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: []  },
      kr: { bin_pallet_conversion_defaults: { pallet_format: { stack_type: 'BIN', pallet_base: 'S' },
                                              basic_pack: 'BX750',
                                              grade: 'SA',
                                              unknown_size_ref: '135',
                                              packed_tm_group: 'UKI',
                                              marketing_org: 'AS',
                                              mark: 'GEN',
                                              inventory_code: 'UL',
                                              sell_by_code: nil },
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            pending_delivery_location: nil,
            default_delivery_location: nil,
            use_bin_asset_control: false,
            presort_legacy_data_fields: %i[ripe_point_code track_indicator_code]  },
      um: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT RECEPTION',
            use_bin_asset_control: false,
            presort_legacy_data_fields: []  },
      ud: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: false,
            convert_carton_to_rebins: false,
            create_farm_location: true,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: []  },
      sr: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: []  },
      sr2: { bin_pallet_conversion_defaults: {},
             delivery_capture_inner_bins: false,
             delivery_capture_container_material: true,
             delivery_capture_container_material_owner: true,
             set_defaults_for_new_rmt_delivery: true,
             convert_carton_to_rebins: true,
             create_farm_location: true,
             pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
             default_delivery_location: 'FRUIT_RECEPTION_1',
             use_bin_asset_control: false,
             presort_legacy_data_fields: []  }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def convert_carton_to_rebins?(explain: false)
      return 'Should bin_tipping convert carton to rebin and then tip it' if explain

      setting(:convert_carton_to_rebins)
    end

    def defaults_for_new_rmt_delivery?(explain: false)
      return 'Should the defaults for new_delivery be set to the values of the latest delivery.' if explain

      setting(:set_defaults_for_new_rmt_delivery)
    end

    def default_bin_pallet_value(code, explain: false)
      return 'Default value for a pallet attribute when converting a bin to a pallet.' if explain

      setting(:bin_pallet_conversion_defaults)[code]
    end

    def capture_inner_bins?(explain: false)
      return 'Do delivered bins contain inner bins (e.g. lugs within larger containers).' if explain

      setting(:delivery_capture_inner_bins)
    end

    def capture_container_material?(explain: false)
      return 'Should the bin material type be recorded.' if explain

      setting(:delivery_capture_container_material)
    end

    def capture_container_material_owner?(explain: false)
      return 'Should the owner of the bin type be recorded.' if explain

      setting(:delivery_capture_container_material_owner)
    end

    def create_farm_location?(explain: false)
      return 'Create a location record for farm.' if explain

      setting(:create_farm_location)
    end

    def pending_delivery_location(explain: false)
      return 'Default location_id for pending PALBIN edi bin receiving.' if explain

      location_long_code = setting(:pending_delivery_location)
      return nil unless location_long_code

      repo = BaseRepo.new
      id = repo.get_id(:locations, location_long_code: location_long_code)
      return id unless id.nil?

      args = {
        location_long_code: location_long_code,
        location_description: location_long_code,
        location_short_code: location_long_code,
        primary_storage_type_id: repo.get_id(:location_storage_types, storage_type_code: 'RMT_BINS'),
        location_type_id: repo.get_id(:location_types, location_type_code: 'FRUIT_RECEPTION'),
        primary_assignment_id: repo.get_id(:location_assignments, assignment_code: 'RECEIVING'),
        can_store_stock: true
      }
      repo.create(:locations, args)
    end

    def default_delivery_location(explain: false)
      return 'Default location_id for PALBIN edi bin receiving.' if explain

      location_long_code = setting(:default_delivery_location)
      return nil unless location_long_code

      repo = BaseRepo.new
      id = repo.get_id(:locations, location_long_code: location_long_code)
      return id unless id.nil?

      args = {
        location_long_code: location_long_code,
        location_description: location_long_code,
        location_short_code: location_long_code,
        primary_storage_type_id: repo.get_id(:location_storage_types, storage_type_code: 'RMT_BINS'),
        location_type_id: repo.get_id(:location_types, location_type_code: 'FRUIT_RECEPTION'),
        primary_assignment_id: repo.get_id(:location_assignments, assignment_code: 'RECEIVING'),
        can_store_stock: true
      }
      repo.create(:locations, args)
    end

    def use_bin_asset_control?(explain: false)
      return 'Use bin asset control to manage bin movements.' if explain

      setting(:use_bin_asset_control)
    end
  end
end
