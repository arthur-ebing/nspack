# frozen_string_literal: true

module Crossbeams
  class ClientRmtRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false },
      hl: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false },
      kr: { bin_pallet_conversion_defaults: { pallet_format: 'xx',
                                              basic_pack: 'xx',
                                              grade: 'xx',
                                              unknown_size_ref: 'xx',
                                              packed_tm_group: 'xx',
                                              marketing_org: 'xx',
                                              mark: 'xx',
                                              inventory_code: 'xx',
                                              sell_by_code: 'xx' },
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true },
      um: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: false,
            delivery_capture_container_material_owner: false },
      ud: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true },
      sr: { bin_pallet_conversion_defaults: {},
            delivery_capture_inner_bins: false,
            delivery_capture_container_material: true,
            delivery_capture_container_material_owner: true },
      sr2: { bin_pallet_conversion_defaults: {},
             delivery_capture_inner_bins: false,
             delivery_capture_container_material: true,
             delivery_capture_container_material_owner: true }
    }.freeze

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
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
  end
end
