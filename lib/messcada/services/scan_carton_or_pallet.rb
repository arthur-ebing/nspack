# frozen_string_literal: true

module MesscadaApp
  class ScanCartonOrPallet < BaseService
    attr_reader :repo, :pallet_was_scanned, :scanned_number, :id

    def initialize(scanned_number)
      @pallet_was_scanned = false
      @scanned_number = scanned_number
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      return failed_response(message) if scanned_number.nil_or_empty?

      scan_value
      carton_or_pallet_id

      response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def response
      instance = ScanCartonOrPalletEntity.new(id: id, pallet_was_scanned: pallet_was_scanned, scanned_number: scanned_number)
      return failed_response(message, instance) unless id

      success_response(message, instance)
    end

    def scan_value
      if scanned_number.length > 8
        @scanned_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: scanned_number).pallet_number
        @pallet_was_scanned = true
      else
        @scanned_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).carton_number
        @pallet_was_scanned = false
      end
    end

    def carton_or_pallet_id
      @id = if @pallet_was_scanned
              repo.get_id(:pallets, pallet_number: scanned_number)
            else
              repo.get_id(:cartons, carton_label_id: scanned_number)
            end
    end

    def message
      return 'scanned number not given' if scanned_number.nil_or_empty?
      return 'Successfully scanned pallet number' if pallet_was_scanned & !id.nil?
      return 'Successfully scanned carton number' if !pallet_was_scanned & !id.nil?

      'Failed to scan number!'
    end
  end
end
