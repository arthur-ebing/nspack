# frozen_string_literal: true

module MesscadaApp
  class CreateRebinFromScannedCartonLabel < BaseService
    attr_reader :repo, :carton_label_id
    attr_accessor :params

    def initialize(carton_label_id, params)
      @carton_label_id = carton_label_id
      @params = params
      @repo = MesscadaApp::MesscadaRepo.new
    end

    def call
      res = create_carton_label_rebin
      return failed_response(unwrap_failed_response(res)) unless res.success

      res
    end

    private

    def create_carton_label_rebin # rubocop:disable Metrics/AbcSize
      return failed_response("Rebin label: #{carton_label_id} could not be found") unless carton_label_exists?
      return failed_response("Pallet already exists for rebin label: #{carton_label_id}") if pallet_exists?
      return failed_response("Rebin label: #{carton_label_id} already verified") if carton_label_rebin_exists?

      params[:verified_from_carton_label_id] = carton_label_id
      res = RmtRebinSchema.call(params)
      return validation_failed_response(res) if res.failure?

      id = repo.create(:rmt_bins, res)
      repo.log_status(:rmt_bins, id, AppConst::VERIFIED_FROM_BIN_LABEL)
      repo.log_status(:carton_labels, carton_label_id, AppConst::VERIFIED_AS_REBIN)

      bin_number = (AppConst::USE_PERMANENT_RMT_BIN_BARCODES ? res.to_h[:bin_asset_number] : id)
      success_response('ok', OpenStruct.new(rebin_id: bin_number, carton_label_id: carton_label_id))
    end

    def carton_label_exists?
      repo.exists?(:carton_labels, id: carton_label_id)
    end

    def pallet_exists?
      pallet_sequence_id = repo.carton_label_carton_palletizing_sequence(carton_label_id)
      pallet_sequence_id ||= repo.carton_label_scanned_from_carton_sequence(carton_label_id)
      pallet_id ||= repo.get(:pallet_sequences, pallet_sequence_id, :pallet_id)

      !pallet_id.nil? && !pallet_sequence_id.nil?
    end

    def carton_label_rebin_exists?
      repo.exists?(:rmt_bins, verified_from_carton_label_id: carton_label_id)
    end
  end
end
