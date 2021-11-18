# frozen_string_literal: true

module MesscadaApp
  class UpdateBinWeights < BaseService
    attr_reader :repo, :bin_number, :gross_weight, :measurement_unit, :force_find_by_id, :weighed_manually, :avg_gross_weight

    def initialize(params, options = {})
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @bin_number = params[:bin_number]
      @gross_weight = params[:gross_weight]
      @measurement_unit = params[:measurement_unit]
      @force_find_by_id = options[:force_find_by_id].nil? ? false : options[:force_find_by_id]
      @weighed_manually = options[:weighed_manually].nil? ? false : options[:weighed_manually]
      @avg_gross_weight = options[:avg_gross_weight].nil? ? false : options[:avg_gross_weight]
    end

    def call
      rmt_bin = find_rmt_bin
      return failed_response("Bin:#{bin_number} could not be found") if rmt_bin.nil?
      return failed_response('Bin Scrapped') if rmt_bin[:scrapped]

      updates = { gross_weight: gross_weight,
                  weighed_manually: weighed_manually,
                  avg_gross_weight: avg_gross_weight }
      tare_weight = repo.get_rmt_bin_tare_weight(rmt_bin)
      updates[:nett_weight] = (gross_weight - tare_weight) if tare_weight

      update_rmt_bin_weights(rmt_bin[:id], updates)

      success_response('RMT Bin weights updated successfully')
    end

    private

    def update_rmt_bin_weights(id, updates)
      repo.update_rmt_bin(id, updates)
    end

    def find_rmt_bin
      return repo.find_bin_by_asset_number(bin_number) unless force_find_by_id

      repo.find_rmt_bin(bin_number)
    end
  end
end
