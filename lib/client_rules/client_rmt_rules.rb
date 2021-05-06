# frozen_string_literal: true

module Crossbeams
  class ClientRmtRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false  },
      hl: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false  },
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
            create_farm_location: false  },
      um: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false },
      ud: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: false,
            convert_carton_to_rebins: false,
            create_farm_location: true  },
      sr: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true,
            set_defaults_for_new_rmt_delivery: true,
            convert_carton_to_rebins: false,
            create_farm_location: false  },
      sr2: { bin_pallet_conversion_defaults: {},
             delivery_capture_inner_bins: false,
             delivery_capture_container_material: true,
             delivery_capture_container_material_owner: true,
             set_defaults_for_new_rmt_delivery: true,
             convert_carton_to_rebins: true,
             create_farm_location: true  }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def convert_carton_to_rebins?(explain: false)
      return 'Should bin_tipping convert carton to rebin and then tip it' if explain

      setting(:convert_carton_to_rebins) && client_code == 'sr2'
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
  end
end
