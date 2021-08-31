# frozen_string_literal: true

module MesscadaApp
  class ScanCartonLabelOrPallet < BaseService
    attr_reader :repo, :params, :mode, :scanned_number, :formatted_number, :expect

    def initialize(params)
      @repo = MesscadaApp::MesscadaRepo.new
      @pallet_was_scanned = false
      @carton_with_pallet_label = false
      @scanned_number = ''
      @expect = params.delete(:expect) if params.respond_to?(:to_h)
      @params = params
      @params = { scanned_number: params.to_s } unless @params.respond_to?(:to_h)
    end

    SCAN = {
      pallet: :resolve_pallet,
      carton_label: :resolve_carton_label,
      legacy_carton_number: :resolve_legacy_carton_number
    }.freeze

    def call # rubocop:disable Metrics/AbcSize
      parse_params
      return failed_response('Nothing Scanned', build_entity(failed: true)) if scanned_number.empty?

      scan_mode = SCAN[mode]
      raise ArgumentError, "Scan mode \"#{mode}\" is unknown for #{self.class}." if scan_mode.nil?

      send(scan_mode)
      return failed_response("Failed to find #{@mode} number: #{@scanned_number}", build_entity(failed: true)) unless @id

      success_response("Successfully scanned #{@mode} number", build_entity)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def build_entity(failed: false)
      ScannedCartonOrPalletResolver.new(
        id: @id,
        failed_scan: failed,
        pallet_was_scanned: @pallet_was_scanned,
        scanned_number: @scanned_number,
        formatted_number: @formatted_number,
        scanned_type: @mode.to_s,
        carton_with_pallet_label: @carton_with_pallet_label,
        carton_equals_pallet_id: @carton_equals_pallet_id,
        carton_id: @carton_id
      )
    end

    def parse_params
      valid_keys = { pallet_number: :pallet,
                     carton_number: :carton_label,
                     carton_label_id: :carton_label,
                     legacy_carton_number: :legacy_carton_number,
                     scanned_number: nil }

      valid_keys.each do |key, scan_mode|
        next unless scanned_number.empty?

        @scanned_number = params.delete(key).to_s
        @mode = scan_mode
      end

      @mode ||= determine_mode

      invalid_keys = params.keys
      raise ArgumentError, "Invalid argument: #{invalid_keys}" if @mode.nil?
    end

    def determine_mode
      case scanned_number.length
      when 1...8
        :carton_label
      when 12
        :legacy_carton_number
      else
        :pallet
      end
    end

    def resolve_pallet
      @formatted_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: scanned_number).pallet_number
      return pallet_scanned_for_carton if expect == :carton_label

      @pallet_was_scanned = true
      @id = repo.get_id(:pallets, pallet_number: formatted_number)
    end

    # A pallet number was scanned on a carton (carton=pallet)
    def pallet_scanned_for_carton
      @pallet_was_scanned = false
      @carton_with_pallet_label = true
      @id = repo.get_id(:carton_labels, pallet_number: formatted_number)
      @carton_id = repo.get_id(:cartons, carton_label_id: @id)
      @carton_equals_pallet_id = repo.get_id(:pallets, pallet_number: formatted_number)
    end

    def resolve_carton_label
      @formatted_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).carton_number
      @id = repo.get_id(:carton_labels, id: formatted_number)
      @carton_id = repo.get_id(:cartons, carton_label_id: @id)
    end

    def resolve_legacy_carton_number
      @formatted_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).legacy_carton_number
      @id = repo.get_value(:legacy_barcodes, :carton_label_id, legacy_carton_number: formatted_number)
      @carton_id = repo.get_id(:cartons, carton_label_id: @id)
    end
  end
end
