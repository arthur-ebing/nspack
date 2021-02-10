# frozen_string_literal: true

module ProductionApp
  class RecalcBinsNettWeight < BaseService
    attr_reader :repo, :messcada_repo, :reworks_run_attrs, :rmt_bins

    def initialize(params, rmt_bins = nil)
      @reworks_run_attrs = params.dup
      @repo = ProductionApp::ReworksRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @rmt_bins = rmt_bins.nil? ? find_bins_for_nett_recalculation : rmt_bins
    end

    def call
      res = recalc_bins_nett_weight
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def find_bins_for_nett_recalculation
      repo.rmt_bins_for_nett_recalculation
    end

    def recalc_bins_nett_weight # rubocop:disable Metrics/AbcSize
      rmt_bin_ids = []
      rmt_bins.each  do |rmt_bin|
        tare_weight = @delivery_repo.get_rmt_bin_tare_weight(rmt_bin)
        repo.update_rmt_bin(rmt_bin[:id], nett_weight: (rmt_bin[:gross_weight] - tare_weight))
        rmt_bin_ids << rmt_bin[:id]
      end

      affected_bins = repo.array_for_db_col(rmt_bin_ids)
      reworks_run_attrs[:pallets_selected] = affected_bins
      reworks_run_attrs[:pallets_affected] = affected_bins
      reworks_run_id = repo.create_reworks_run(reworks_run_attrs)
      repo.log_status(:reworks_runs, reworks_run_id, 'CREATED')
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
