# frozen_string_literal: true

module FinishedGoodsApp
  class PalletMovementsInteractor < BaseInteractor
    def move_pallet(pallet_number, location, is_location_scanned)
      pallet = ProductionApp::ProductionRunRepo.new.find_pallet_by_pallet_number(pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet does not exist'] }) unless pallet

      location_id = location
      location_id = get_location_id_by_barcode(location) unless is_location_scanned

      repo.transaction do
        FinishedGoodsApp::MoveStockService.new('PALLET', pallet[:id], location_id, 'MOVE_PALLET', nil).call
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    private

    def get_location_id_by_barcode(location_barcode)
      repo.get_location_id_by_barcode(location_barcode)
    end

    def repo
      @repo ||= FinishedGoodsApp::LoadRepo.new
    end
  end
end
