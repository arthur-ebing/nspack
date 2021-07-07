# frozen_string_literal: true

require File.join(File.expand_path('../../lib', __dir__), 'crossbeams_responses')

module Crossbeams
  class ClientFgRules < BaseClientRules # rubocop:disable Metrics/ClassLength
    include Crossbeams::AutoDocumentation
    include Crossbeams::Responses

    CLIENT_SETTINGS = {
      hb: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: false,
            reporting_industry: { default: 'citrus', can_override: true },
            integrate_extended_fg: false,
            max_rmt_bins_on_load: 80,
            max_pallets_on_load: 96,
            use_inspection_destination_for_load_out: true,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      hl: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: false,
            reporting_industry: { default: 'melons', can_override: false },
            integrate_extended_fg: false,
            max_rmt_bins_on_load: 50,
            max_pallets_on_load: 120,
            use_inspection_destination_for_load_out: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      kr: { place_of_issue_for_addendum: 'CPT',
            vgm_required: true,
            reporting_industry: { default: nil, can_override: false },
            integrate_extended_fg: true,
            max_rmt_bins_on_load: 50,
            max_pallets_on_load: 50,
            use_inspection_destination_for_load_out: false,
            valid_pallet_destination: { failed: [/\AREWORKS$/], pending: [/\AREWORKS$/, /\ARA_10/, /\APACKHSE/], loaded: [/\APART_PALLETS/] } },
      um: { place_of_issue_for_addendum: nil,
            vgm_required: true,
            reporting_industry: { default: nil, can_override: false },
            integrate_extended_fg: false,
            max_rmt_bins_on_load: 78,
            max_pallets_on_load: 40,
            use_inspection_destination_for_load_out: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      ud: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: true,
            reporting_industry: { default: 'citrus', can_override: false },
            integrate_extended_fg: false,
            max_rmt_bins_on_load: 50,
            max_pallets_on_load: 50,
            use_inspection_destination_for_load_out: false,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      sr: { place_of_issue_for_addendum: 'PLZ',
            vgm_required: true,
            reporting_industry: { default: 'citrus', can_override: false },
            integrate_extended_fg: false,
            max_rmt_bins_on_load: 80,
            max_pallets_on_load: 80,
            use_inspection_destination_for_load_out: true,
            valid_pallet_destination: { failed: [/.+/], pending: [/.+/], loaded: [/.+/] } },
      sr2: { place_of_issue_for_addendum: 'PLZ',
             vgm_required: true,
             reporting_industry: { default: 'citrus', can_override: false },
             integrate_extended_fg: false,
             max_rmt_bins_on_load: 80,
             max_pallets_on_load: 80,
             use_inspection_destination_for_load_out: true,
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
    # PALLET_WEIGHT_REQUIRED_FOR_INSPECTION
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

    def valid_tripsheet_pallet_destination(pallet_number, location, inspections, pallet_on_load, explain: false) # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity,  Metrics/PerceivedComplexity
      return 'Validate tripsheet pallet planned location.' if explain

      state = if !inspections[:failed].nil_or_empty?
                :failed
              elsif !inspections[:pending].nil_or_empty?
                :pending
              elsif pallet_on_load
                :loaded
              end
      return ok_response if state.nil? || setting(:valid_pallet_destination)[state].any? { |rule| !(location =~ rule).nil? }

      err = case state
            when :failed
              "Invalid destination[#{location}]. Pallet[#{pallet_number}] has failed inspections: #{inspections[:failed].join(',')}"
            when :pending
              "Invalid destination[#{location}]. Pallet[#{pallet_number}] has pending inspections: #{inspections[:pending].join(',')}"
            when :loaded
              "Invalid destination[#{location}]. Pallet[#{pallet_number}] loaded out"
            end
      failed_response(err)
    end

    def max_pallet_count_for_load?(explain: false)
      return 'Limits the amount of pallets that can be loaded.' if explain

      setting(:max_pallets_on_load)
    end

    def max_bin_count_for_load?(explain: false)
      return 'Limits the amount of RMT Bins that can be loaded.' if explain

      setting(:max_rmt_bins_on_load)
    end

    def use_inspection_destination_for_load_out?(explain: false)
      return 'Default value for govt_inspection_sheets.use_inspection_destination_for_load_out.' if explain

      setting(:use_inspection_destination_for_load_out)
    end

    def reporting_industry(plant_resource_code: nil, explain: false)
      return "Reporting industry. Blank for default, otherwise citrus or melons. Used in Japser reporting to load different finding sheet reports. Setting: #{setting(:reporting_industry).inspect}" if explain

      reporting_industry = setting(:reporting_industry)
      return reporting_industry[:default] unless reporting_industry[:can_override]
      return reporting_industry[:default] if plant_resource_code.nil?

      ph_industry = DB[:plant_resources]
                    .where(plant_resource_code: plant_resource_code)
                    .get(Sequel.lit("resource_properties ->> 'reporting_industry'"))
      ph_industry.nil_or_empty? ? reporting_industry[:default] : ph_industry
    end
  end
end
