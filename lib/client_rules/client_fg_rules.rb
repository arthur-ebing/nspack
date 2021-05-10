# frozen_string_literal: true

require File.join(File.expand_path('../../lib', __dir__), 'crossbeams_responses')

module Crossbeams
  class ClientFgRules < BaseClientRules
    include Crossbeams::AutoDocumentation
    include Crossbeams::Responses

    CLIENT_SETTINGS = {
      hb: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: false,
            integrate_extended_fg: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      hl: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: false,
            integrate_extended_fg: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      kr: { place_of_issue_for_addendum: 'CPT',
            vgm_required: true,
            integrate_extended_fg: true,
            valid_pallet_destination: { failed: [/\AREWORKS$/], pending: [/\AREWORKS$/, /\ARA_10/, /\APACKHSE/], loaded: [/\APART_PALLETS/] } },
      um: { place_of_issue_for_addendum: nil,
            vgm_required: true,
            integrate_extended_fg: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      ud: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: true,
            integrate_extended_fg: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      sr: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: true,
            integrate_extended_fg: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      sr2: { place_of_issue_for_addendum: 'PLZ',
             vgm_required: true,
             integrate_extended_fg: false,
             valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } }
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

    def do_titan_inspections?(explain: false)
      return 'Enable TITAN inspections when API user is given.' if explain

      !AppConst::TITAN_INSPECTION_API_USER_ID.nil?
    end

    def do_titan_addenda?(explain: false)
      return 'Enable TITAN addenda when API user is given.' if explain

      !AppConst::TITAN_ADDENDUM_API_USER_ID.nil?
    end

    def valid_destination?(pallet_number, location, inspections, pallet_on_load, explain: false) # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      return 'Validate tripsheet pallet planned location.' if explain

      err = nil
      if !inspections[:failed].nil_or_empty? && setting(:valid_pallet_destination)[:failed].none? { |rule| !(location =~ rule).nil? }
        err = "Invalid destination[#{location}]. Pallet[#{pallet_number}] has failed inspections: #{inspections[:failed].join(',')}"
      elsif !inspections[:pending].nil_or_empty? && setting(:valid_pallet_destination)[:pending].none? { |rule| !(location =~ rule).nil? }
        err = "Invalid destination[#{location}]. Pallet[#{pallet_number}] has pending inspections: #{inspections[:pending].join(',')}"
      elsif !pallet_on_load.nil? && setting(:valid_pallet_destination)[:loaded].none? { |rule| !(location =~ rule).nil? }
        err = "Invalid destination[#{location}]. Pallet[#{pallet_number}] loaded out"
      end

      err.nil? ? ok_response : failed_response(err)
    end
  end
end
