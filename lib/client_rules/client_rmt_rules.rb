# frozen_string_literal: true

module Crossbeams
  class ClientRmtRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { bin_pallet_conversion_defaults: {},
            presort_staging_target_location: {},
            delivery_capture_inner_bins: false,
            sample_rmt_bin_percentage: 0,
            use_raw_material_code: false,
            classify_raw_material: false,
            use_delivery_destination: false,
            bin_valid_for_external_integration: false,
            default_container_material_owner: nil,
            default_rmt_container_type: 'BIN',
            all_delivery_bins_of_same_type: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            maintain_legacy_columns: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: [],
            presort_plant_integration: false,
            show_kromco_attributes: false,
            create_depot_location: false,
            create_bin_asset_trading_partner_location: false,
            enforce_mrl_check: false   },
      hl: { bin_pallet_conversion_defaults: {},
            presort_staging_target_location: {},
            delivery_capture_inner_bins: false,
            sample_rmt_bin_percentage: 0,
            use_raw_material_code: false,
            classify_raw_material: false,
            use_delivery_destination: false,
            bin_valid_for_external_integration: false,
            default_container_material_owner: nil,
            default_rmt_container_type: 'BIN',
            all_delivery_bins_of_same_type: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            maintain_legacy_columns: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: [],
            presort_plant_integration: false,
            show_kromco_attributes: false,
            create_depot_location: false,
            create_bin_asset_trading_partner_location: false,
            enforce_mrl_check: false   },
      kr: { bin_pallet_conversion_defaults: { pallet_format: { stack_type: 'BIN', pallet_base: 'S' },
                                              basic_pack: 'BX750',
                                              grade: 'SA',
                                              unknown_size_ref: '135',
                                              packed_tm_group: 'UKI',
                                              marketing_org: 'AS',
                                              mark: 'GEN',
                                              inventory_code: 'UL',
                                              sell_by_code: nil },
            presort_staging_target_location: { PRESORT_STAGING_1: 'PRESORT_1', PRESORT_STAGING_2: 'PRESORT_2' },
            delivery_capture_inner_bins: false,
            sample_rmt_bin_percentage: 0.05,
            use_raw_material_code: true,
            classify_raw_material: true,
            use_delivery_destination: true,
            bin_valid_for_external_integration: true,
            default_container_material_owner: 'KROMCO',
            default_rmt_container_type: 'BIN',
            all_delivery_bins_of_same_type: true,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: true,
            maintain_legacy_columns: true,
            pending_delivery_location: nil,
            default_delivery_location: 'FRUIT RECEPTION',
            use_bin_asset_control: true,
            presort_legacy_data_fields: %i[treatment_code ripe_point_code track_indicator_code],
            presort_plant_integration: true,
            show_kromco_attributes: true,
            create_depot_location: true,
            create_bin_asset_trading_partner_location: true,
            enforce_mrl_check: true   },
      um: { bin_pallet_conversion_defaults: {},
            presort_staging_target_location: {},
            delivery_capture_inner_bins: false,
            sample_rmt_bin_percentage: 0,
            use_raw_material_code: false,
            classify_raw_material: false,
            use_delivery_destination: false,
            bin_valid_for_external_integration: false,
            default_container_material_owner: nil,
            default_rmt_container_type: 'BIN',
            all_delivery_bins_of_same_type: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            maintain_legacy_columns: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT RECEPTION',
            use_bin_asset_control: false,
            presort_legacy_data_fields: [],
            presort_plant_integration: false,
            show_kromco_attributes: false,
            create_depot_location: false,
            create_bin_asset_trading_partner_location: false,
            enforce_mrl_check: false   },
      ud: { bin_pallet_conversion_defaults: {},
            presort_staging_target_location: {},
            delivery_capture_inner_bins: false,
            sample_rmt_bin_percentage: 0,
            use_raw_material_code: false,
            classify_raw_material: false,
            use_delivery_destination: true,
            bin_valid_for_external_integration: false,
            default_container_material_owner: nil,
            default_rmt_container_type: 'BIN',
            all_delivery_bins_of_same_type: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: false,
            convert_carton_to_rebins: false,
            create_farm_location: true,
            maintain_legacy_columns: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: [],
            presort_plant_integration: false,
            show_kromco_attributes: false,
            create_depot_location: false,
            create_bin_asset_trading_partner_location: false,
            enforce_mrl_check: false   },
      cfg: { bin_pallet_conversion_defaults: {},
             presort_staging_target_location: {},
             delivery_capture_inner_bins: false,
             sample_rmt_bin_percentage: 0,
             use_raw_material_code: false,
             classify_raw_material: false,
             use_delivery_destination: false,
             bin_valid_for_external_integration: false,
             default_container_material_owner: 'CFG',
             default_rmt_container_type: 'BIN',
             all_delivery_bins_of_same_type: false,
             delivery_capture_container_material: false,
             delivery_capture_container_material_owner: false,
             set_defaults_for_new_rmt_delivery: false,
             convert_carton_to_rebins: false,
             create_farm_location: false,
             maintain_legacy_columns: false,
             pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
             default_delivery_location: 'FRUIT_RECEPTION_1',
             use_bin_asset_control: false,
             presort_legacy_data_fields: [],
             presort_plant_integration: false,
             show_kromco_attributes: false,
             create_depot_location: false,
             create_bin_asset_trading_partner_location: false,
             enforce_mrl_check: false  },
      sr: { bin_pallet_conversion_defaults: {},
            presort_staging_target_location: {},
            delivery_capture_inner_bins: false,
            sample_rmt_bin_percentage: 0,
            use_raw_material_code: false,
            classify_raw_material: false,
            use_delivery_destination: true,
            bin_valid_for_external_integration: false,
            default_container_material_owner: nil,
            default_rmt_container_type: 'BIN',
            all_delivery_bins_of_same_type: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false,
            maintain_legacy_columns: false,
            pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
            default_delivery_location: 'FRUIT_RECEPTION_1',
            use_bin_asset_control: false,
            presort_legacy_data_fields: [],
            presort_plant_integration: false,
            show_kromco_attributes: false,
            create_depot_location: false,
            create_bin_asset_trading_partner_location: false,
            enforce_mrl_check: false    },
      sr2: { bin_pallet_conversion_defaults: {},
             presort_staging_target_location: {},
             delivery_capture_inner_bins: false,
             sample_rmt_bin_percentage: 0,
             use_raw_material_code: false,
             classify_raw_material: false,
             use_delivery_destination: true,
             bin_valid_for_external_integration: false,
             default_container_material_owner: nil,
             default_rmt_container_type: 'BIN',
             all_delivery_bins_of_same_type: false,
             delivery_capture_container_material: true,
             delivery_capture_container_material_owner: true,
             set_defaults_for_new_rmt_delivery: true,
             convert_carton_to_rebins: true,
             create_farm_location: true,
             maintain_legacy_columns: false,
             pending_delivery_location: 'IN_TRANSIT_TO_PACKHOUSE',
             default_delivery_location: 'FRUIT_RECEPTION_1',
             use_bin_asset_control: false,
             presort_legacy_data_fields: [],
             presort_plant_integration: false,
             show_kromco_attributes: false,
             create_depot_location: false,
             create_bin_asset_trading_partner_location: false,
             enforce_mrl_check: false   }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def implements_presort_legacy_data_fields?(explain: false)
      return 'Should presorting store legacy data' if explain

      !setting(:presort_legacy_data_fields).empty?
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

    def presort_staging_target_location(plant, explain: false)
      return 'Location of the newly created presorted bin.' if explain

      setting(:presort_staging_target_location)["PRESORT_STAGING_#{plant[-1]}".to_sym]
    end

    def use_raw_material_code?(explain: false)
      return "Allows user to set a delivery's rmt_code." if explain

      setting(:use_raw_material_code)
    end

    def classify_raw_material?(explain: false)
      return "Allows user to set a delivery's rmt_classifications." if explain

      setting(:classify_raw_material)
    end

    def show_classify_raw_material_form?(explain: false)
      return 'Allows user to see the classify_raw_material form.' if explain

      setting(:use_raw_material_code) || setting(:classify_raw_material)
    end

    def include_destination_in_delivery?(explain: false)
      return 'Should the destination be included in the rmt_delivery.' if explain

      setting(:use_delivery_destination)
    end

    def sample_rmt_bin_percentage(explain: false)
      return 'The percentage of bins on a delivery to be identified as sample bins (when applicable).' if explain

      setting(:sample_rmt_bin_percentage)
    end

    def check_external_bin_valid_for_integration?(explain: false)
      return 'Is the external bin valid for integration.' if explain

      setting(:bin_valid_for_external_integration)
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

    def maintain_legacy_columns?(explain: false)
      return 'Maintain legacy columns for rebins.' if explain

      setting(:maintain_legacy_columns)
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
        primary_assignment_id: repo.get_id(:location_assignments, assignment_code: 'FRUIT_RECEPTION'),
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
        primary_assignment_id: repo.get_id(:location_assignments, assignment_code: 'FRUIT_RECEPTION'),
        can_store_stock: true
      }
      repo.create(:locations, args)
    end

    def default_container_material_owner(explain: false)
      return 'Org long_description used in presort bin_created integration service as the container_material_owner.' if explain

      setting(:default_container_material_owner)
    end

    def default_rmt_container_type(explain: false)
      return 'Container type used in presort bin_created integration service.' if explain

      setting(:default_rmt_container_type)
    end

    def all_delivery_bins_of_same_type?(explain: false)
      return 'Are all bins on a delivery always of the same type. If true, bin type and owner can be set at delivery instead of for every bin individually.' if explain

      setting(:all_delivery_bins_of_same_type)
    end

    def use_bin_asset_control?(explain: false)
      return 'Use bin asset control to manage bin movements.' if explain

      setting(:use_bin_asset_control)
    end

    def presort_plant_integration?(explain: false)
      return 'Does bin carry attributes originating from external presort system' if explain

      setting(:presort_plant_integration)
    end

    def show_kromco_attributes?(explain: false)
      return 'Display attributes unique to Kromco - typically originating from legacy Kromco system' if explain

      setting(:show_kromco_attributes)
    end

    def create_depot_location?(explain: false)
      return 'Create a location record for depot.' if explain

      setting(:create_depot_location)
    end

    def create_bin_asset_trading_partner_location?(explain: false)
      return 'Create a location record for depot.' if explain

      setting(:create_bin_asset_trading_partner_location)
    end

    def enforce_mrl_check?(explain: false)
      return 'Enforce MRL check for deliveries.' if explain

      setting(:enforce_mrl_check)
    end
  end
end
