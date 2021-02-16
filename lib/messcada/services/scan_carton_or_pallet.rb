# frozen_string_literal: true

module MesscadaApp
  class ScanCartonOrPallet < BaseService
    attr_reader :repo, :carton_id, :carton, :pallet_id, :pallet, :scanned_number

    def initialize(scanned_number)
      @carton_id = nil
      @carton = false
      @pallet_id = nil
      @pallet = false
      @scanned_number = scanned_number
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      return response(false, message) if scanned_number.nil_or_empty?

      scan_pallet_or_carton_number

      response(true, message)
    rescue Crossbeams::InfoError => e
      response(false, e.message)
    end

    private

    def scan_pallet_or_carton_number
      if scanned_number.length > 8
        pallet_number = MesscadaApp::ScannedPalletNumber.new(scanned_pallet_number: scanned_number).pallet_number
        @pallet_id = repo.get_id(:pallets, pallet_number: pallet_number)
        @pallet = true
      else
        carton_number = MesscadaApp::ScannedCartonNumber.new(scanned_carton_number: scanned_number).carton_number
        @carton_id = repo.get_id(:cartons, carton_label_id: carton_number)
        @carton = true
        get_pallet_from_carton(carton_number)
      end
    end

    def get_pallet_from_carton(carton_number)
      pallet_sequence_id = if !AppConst::CARTON_EQUALS_PALLET && AppConst::USE_CARTON_PALLETIZING
                             repo.get_value(:cartons, :pallet_sequence_id, carton_label_id: carton_number)
                           else
                             DB[:pallet_sequences].join(:cartons, id: :scanned_from_carton_id).where(carton_label_id: carton_number).select_map(Sequel[:pallet_sequences][:id]).first
                           end

      @pallet_id = repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)
    end

    def response(success, message)
      OpenStruct.new(success: success,
                     pallet?: pallet?,
                     pallet_id: pallet_id,
                     carton?: carton?,
                     carton_id: carton_id,
                     message: message)
    end

    def message
      return 'scanned number not given' if scanned_number.nil_or_empty?
      return 'Successfully scanned pallet number' if pallet?
      return 'Successfully scanned carton number' if carton?

      'Failed to scan number!'
    end

    def pallet?
      @pallet
    end

    def carton?
      @carton
    end
  end
end
