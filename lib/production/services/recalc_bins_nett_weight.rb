# frozen_string_literal: true

module ProductionApp
  class RecalcBinsNettWeight < BaseService
    attr_reader :repo, :messcada_repo, :rmt_bins

    def initialize(rmt_bins = nil)
      @repo = ProductionApp::ReworksRepo.new
      @delivery_repo = RawMaterialsApp::RmtDeliveryRepo.new
      @rmt_bins = rmt_bins.nil? ? find_all_rmt_bins : rmt_bins
    end

    def call
      res = recalc_bins_nett_weight
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def find_all_rmt_bins
      repo.find_all_rmt_bins
    end

    def recalc_bins_nett_weight
      rmt_bins.each  do |rmt_bin|
        tare_weight = @delivery_repo.get_rmt_bin_tare_weight(rmt_bin)

        repo.update_rmt_bin(rmt_bin[:id], nett_weight: ((rmt_bin[:gross_weight] || AppConst::BIG_ZERO) - tare_weight))
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
