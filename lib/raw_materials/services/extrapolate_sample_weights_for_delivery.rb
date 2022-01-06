# frozen_string_literal: true

module RawMaterialsApp
  class  ExtrapolateSampleWeightsForDelivery < BaseService
    attr_reader :repo, :rmt_delivery_id

    def initialize(rmt_delivery_id)
      @rmt_delivery_id = rmt_delivery_id
      @repo = RawMaterialsApp::RmtDeliveryRepo.new
    end

    def call
      res = validate
      return res unless res.success

      extrapolate_sample_weights
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def validate
      res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:exists, rmt_delivery_id)
      return res unless res.success

      res = RawMaterialsApp::TaskPermissionCheck::RmtDelivery.call(:delivery_tipped, rmt_delivery_id)
      return res unless res.success

      ok_response
    end

    def extrapolate_sample_weights # rubocop:disable Metrics/AbcSize
      cultivar_id = repo.get(:rmt_deliveries, :cultivar_id, rmt_delivery_id)
      return ok_response unless repo.extrapolate_sample_weights?(cultivar_id)
      return ok_response if missing_sample_bin_weights?

      average_weight = repo.average_sample_full_bin_weight_for(rmt_delivery_id)
      unless average_weight.nil?
        repo.update(:rmt_bins, non_sample_bin_ids, nett_weight: average_weight)
        repo.update(:rmt_deliveries, rmt_delivery_id, sample_bins_weighed: true, sample_weights_extrapolated_at: Time.now)
        repo.log_status(:rmt_deliveries, rmt_delivery_id, 'SAMPLE_WEIGHTS_APPLIED')
      end

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def missing_sample_bin_weights?
      repo.exists?(:rmt_bins, rmt_delivery_id: rmt_delivery_id, sample_bin: true, nett_weight: nil)
    end

    def non_sample_bin_ids
      repo.select_values(:rmt_bins, :id, rmt_delivery_id: rmt_delivery_id, sample_bin: false)
    end
  end
end
