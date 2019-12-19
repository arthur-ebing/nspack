# frozen_string_literal: true

module MesscadaApp
  class UpdateBinWeights < BaseService
    attr_reader :repo, :bin_number, :gross_weight, :measurement_unit, :force_find_by_id

    def initialize(params, force_find_by_id = false)
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @bin_number = params[:bin_number]
      @gross_weight = params[:gross_weight]
      @measurement_unit = params[:measurement_unit]
      @force_find_by_id = force_find_by_id
    end

    def call
      rmt_bin = find_rmt_bin
      return failed_response("Bin:#{bin_number} could not be found") if rmt_bin.nil?

      updates = { gross_weight: gross_weight }
      tare_weight = repo.get_rmt_bin_tare_weight(rmt_bin)
      updates[:nett_weight] = (gross_weight - tare_weight) if tare_weight

      update_rmt_bin_weights(rmt_bin[:id], updates)

      success_response('rmt bin weights updated successfully')
    end

    private

    def update_rmt_bin_weights(id, updates)
      repo.transaction do
        repo.update_rmt_bin(id, updates)
      end
    end

    def find_rmt_bin
      unless force_find_by_id
        return repo.find_bin_by_asset_number(bin_number) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      end

      repo.find_rmt_bin(bin_number)
    end
  end
end
