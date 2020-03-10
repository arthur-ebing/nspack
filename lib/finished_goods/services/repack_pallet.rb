# frozen_string_literal: true

module FinishedGoodsApp
  class RepackPallet < BaseService
    attr_reader :repo, :pallet_id, :pallet_number, :user_name

    def initialize(pallet_id, user_name)
      @pallet_id = pallet_id
      @user_name = user_name
      @repo = ProductionApp::ReworksRepo.new
    end

    def call
      pallet = find_pallet
      @pallet_number = pallet[:pallet_number]

      res = repack_pallet
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response("Pallet number: #{pallet_number} was successfully repacked.",
                       new_pallet_id: res.instance[:new_pallet_id])
    end

    private

    def find_pallet
      repo.pallet(pallet_id)
    end

    def repack_pallet
      res = repo.repack_pallet(pallet_id)
      return res unless res.success

      new_pallet_id = res.instance[:new_pallet_id]
      res = create_reworks_run
      return res unless res.success

      success_response('ok',
                       new_pallet_id: new_pallet_id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_reworks_run  # rubocop:disable Metrics/AbcSize
      reworks_run_type_id = repo.get_reworks_run_type_id(AppConst::RUN_TYPE_SCRAP_PALLET)
      return failed_response("Reworks Run Type : #{AppConst::RUN_TYPE_SCRAP_PALLET} does not exist. Perhaps required seeds were not run. Please contact support.") if reworks_run_type_id.nil?

      scrap_reason_id = repo.get_scrap_reason_id(AppConst::REWORKS_REPACK_SCRAP_REASON)
      return failed_response("Scrap Reason : #{AppConst::REWORKS_REPACK_SCRAP_REASON} does not exist. Perhaps required seeds were not run. Please contact support.") if scrap_reason_id.nil?

      repo.create_reworks_run(user: user_name,
                              reworks_run_type_id: reworks_run_type_id,
                              scrap_reason_id: scrap_reason_id,
                              remarks: AppConst::REWORKS_REPACK_SCRAP_REASON,
                              pallets_scrapped: "{ #{pallet_number} }",
                              pallets_affected: "{ #{pallet_number} }")

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
