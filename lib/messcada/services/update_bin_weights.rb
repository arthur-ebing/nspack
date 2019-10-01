# frozen_string_literal: true

module MesscadaApp
  class UpdateBinWeights < BaseService
    attr_reader :repo, :bin_number, :gross_weight, :measurement_unit

    def initialize(params)
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
      @bin_number = params[:bin_number]
      @gross_weight = params[:gross_weight]
      @measurement_unit = params[:measurement_unit]
    end

    def call
      rmt_bin = find_rmt_bin
      return failed_response("Bin:#{bin_number} could not be found") if rmt_bin.nil?

      updates = { gross_weight: gross_weight }
      tare_weight = get_rmt_bin_tare_weight(rmt_bin)
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
      return repo.find_bin_by_asset_number(bin_number) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES == 'true'

      repo.find_rmt_bin(bin_number)
    end

    def get_rmt_bin_tare_weight(rmt_bin)
      tare_weight = repo.find_rmt_container_material_type_tare_weight(rmt_bin[:rmt_container_material_type_id])
      return tare_weight unless tare_weight.nil?

      repo.find_rmt_container_type_tare_weight(rmt_bin[:rmt_container_type_id])
    end
  end
end
