# frozen_string_literal: true

module ProductionApp
  class BulkWeighBins < BaseService
    attr_reader :repo, :rmt_bin_numbers, :gross_weight, :force_find_by_id, :avg_gross_weight

    def initialize(params,  force_find_by_id = false, avg_gross_weight = false)
      @repo = ProductionApp::ReworksRepo.new
      @rmt_bin_numbers = params[:pallets_selected]
      @gross_weight = params[:gross_weight]
      @force_find_by_id = force_find_by_id
      @avg_gross_weight = avg_gross_weight
    end

    def call
      res = manually_weigh_bins
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      ok_response
    end

    private

    def manually_weigh_bins
      rmt_bin_numbers.each  do |bin_number|
        attrs = { bin_number: bin_number,
                  gross_weight: gross_weight,
                  measurement_unit: 'KG',
                  weighed_manually: true,
                  avg_gross_weight: avg_gross_weight }

        options = { force_find_by_id: force_find_by_id, weighed_manually: true, avg_gross_weight: avg_gross_weight }
        res = MesscadaApp::UpdateBinWeights.call(attrs, options)
        return res unless res.success
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
