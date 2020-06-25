# frozen_string_literal: true

module MesscadaApp
  class CompletePallet < BaseService
    attr_reader :repo, :pallet_id

    def initialize(pallet_id)
      @pallet_id = pallet_id
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      return failed_response("Pallet :#{pallet_id} does not exist") unless pallet_exists?

      res = complete_pallet
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', pallet_id: pallet_id)
    end

    private

    def pallet_exists?
      repo.exists?(:pallets, id: pallet_id)
    end

    def complete_pallet
      repo.update_pallet(pallet_id, { palletized: true, palletized_at: Time.now, status: AppConst::PALLETIZING })
      repo.log_status('pallets', pallet_id, AppConst::PALLET_COMPLETED_ON_BAY)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
