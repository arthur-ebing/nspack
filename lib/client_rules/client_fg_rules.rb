# frozen_string_literal: true

module Crossbeams
  class ClientFgRules < BaseClientRules
    include Crossbeams::AutoDocumentation

    CLIENT_SETTINGS = {
      hb: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: false,
            integrate_extended_fg: false },
      hl: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: false,
            integrate_extended_fg: false },
      kr: { place_of_issue_for_addendum: 'CPT',
            vgm_required: true,
            integrate_extended_fg: true },
      um: { place_of_issue_for_addendum: nil,
            vgm_required: true,
            integrate_extended_fg: false },
      ud: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: true,
            integrate_extended_fg: false },
      sr: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: true,
            integrate_extended_fg: false },
      sr2: { place_of_issue_for_addendum: 'PLZ',
             vgm_required: false,
             integrate_extended_fg: false }
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

    def initialize(client_code)
      super
      @settings = CLIENT_SETTINGS.fetch(client_code.to_sym)
    end

    def verified_gross_mass_required_for_loads?(explain: false)
      return 'Do loads have to have a verified gross mass.' if explain

      setting(:vgm_required)
    end

    def lookup_extended_fg_code?(explain: false)
      return 'Should the extended_fg_code be looked up from an external system.' if explain

      setting(:integrate_extended_fg)
    end
  end
end
