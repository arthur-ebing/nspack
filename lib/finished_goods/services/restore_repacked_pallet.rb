# frozen_string_literal: true

module FinishedGoodsApp
  class RestoreRepackedPallet < BaseService
    attr_reader :repo, :pallet_id, :original_pallet_id

    def initialize(pallet_id)
      @repo = ProductionApp::ReworksRepo.new
      @pallet_id = pallet_id
      @original_pallet_id = repo.repacked_from_pallet_id_for_pallet(pallet_id)
    end

    def call
      res = restore_repacked_pallet
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('Restored repacked pallet(s) successfully.',
                       original_pallet_id: original_pallet_id)
    end

    private

    def restore_repacked_pallet
      return failed_response('Pallet does not exist') if original_pallet_id.nil_or_empty?

      res = repo.restore_repacked_pallet(pallet_id, original_pallet_id)
      return res unless res.success

      res = move_stock_pallet
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def move_stock_pallet # rubocop:disable Metrics/AbcSize
      opts = { pallet_id => MasterfilesApp::LocationRepo.new.find_location_by_location_long_code(AppConst::SCRAP_LOCATION)&.id,
               original_pallet_id => repo.packhouse_location_id_for_pallet(pallet_id) }

      [pallet_id, original_pallet_id].each do |pallet_id|
        location_to_id = opts[pallet_id]
        return failed_response('Location does not exist') if location_to_id.nil_or_empty?

        res = FinishedGoodsApp::MoveStockService.call(AppConst::PALLET_STOCK_TYPE, pallet_id, location_to_id, AppConst::REWORKS_MOVE_PALLET_BUSINESS_PROCESS, nil)
        return res unless res.success
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
