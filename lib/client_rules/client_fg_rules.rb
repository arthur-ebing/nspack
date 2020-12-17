# frozen_string_literal: true

module Crossbeams
  class ClientFgRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { place_of_issue_for_addendum: 'PLZ' },
      hl: { place_of_issue_for_addendum: 'PLZ' },
      kr: { place_of_issue_for_addendum: 'CPT' },
      um: { place_of_issue_for_addendum: nil },
      ud: { place_of_issue_for_addendum: 'PLZ' },
      sr: { place_of_issue_for_addendum: 'PLZ' },
      sr2: { place_of_issue_for_addendum: 'PLZ' }
    }.freeze
    # ALLOW_EXPORT_PALLETS_TO_BYPASS_INSPECTION
    # CALCULATE_PALLET_DECK_POSITIONS
    # DEFAULT_CARGO_TEMP_ON_ARRIVAL
    # DEFAULT_DEPOT
    # DEFAULT_EXPORTER
    # DEFAULT_FIRST_INTAKE_LOCATION
    # DEFAULT_INSPECTION_BILLING
    # GOVT_INSPECTION_SIGNEE_CAPTION
    # IN_TRANSIT_LOCATION
    # LOCATION_TYPES_COLD_BAY_DECK
    # MAX_PALLETS_ON_LOAD
    # PALLET_WEIGHT_REQUIRED_FOR_INSPECTION
    # RPT_INDUSTRY
    # TEMP_TAIL_REQUIRED_TO_SHIP
    # VGM_REQUIRED

    def initialize(client_code)
      super()
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end
  end
end
