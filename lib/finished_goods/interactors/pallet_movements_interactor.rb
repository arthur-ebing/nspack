# frozen_string_literal: true

module FinishedGoodsApp
  class PalletMovementsInteractor < BaseInteractor
    def move_pallet(pallet_number, location, location_scan_field) # rubocop:disable Metrics/AbcSize
      pallet = ProductionApp::ProductionRunRepo.new.find_pallet_by_pallet_number(pallet_number)
      return validation_failed_response(messages: { pallet_number: ['Pallet does not exist'] }) unless pallet

      location_id = MasterfilesApp::LocationRepo.new.resolve_location_id_from_scan(location, location_scan_field)
      return validation_failed_response(messages: { location: ['Location does not exist'] }) if location_id.nil_or_empty?

      repo.transaction do
        FinishedGoodsApp::MoveStockService.new(AppConst::PALLET_STOCK_TYPE, pallet[:id], location_id, 'MOVE_PALLET', nil).call
      end
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def set_local_pallet # rubocop:disable Metrics/AbcSize
      args = { in_stock: false, packed_tm_group: 'LO' }
      pallet_sequence = repo.all_hash(:vw_pallet_sequence_flat, args)
      pallet_ids = pallet_sequence.map { |seq| seq[:pallet_id] }
      pallet_numbers = pallet_sequence.map { |seq| seq[:pallet_number] }

      repo.transaction do
        repo.update(:pallets, pallet_ids, in_stock: true, stock_created_at: Time.now)
        log_multiple_statuses(:pallets, pallet_ids, 'ACCEPTED_AS_LOCAL_STOCK')
        log_transaction
      end

      success_response("Updated pallets #{pallet_numbers.join(', ')}")
    rescue Crossbeams::InfoError => e
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
