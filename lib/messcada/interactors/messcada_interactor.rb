# frozen_string_literal: true

module MesscadaApp
  class MesscadaInteractor < BaseInteractor
    def update_rmt_bin_weights(params)
      res = validate_update_rmt_bin_weights_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      MesscadaApp::UpdateBinWeights.new(res).call
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def tip_rmt_bin(params) # rubocop:disable Metrics/AbcSize
      res = validate_tip_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        res = MesscadaApp::TipBin.new(res).call
        if res.success
          log_status('rmt_bins', res.instance[:rmt_bin_id], 'TIPPED')
          log_transaction
        end
        res
      end
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= MesscadaRepo.new
    end

    def validate_update_rmt_bin_weights_params(params)
      UpdateRmtBinWeightsSchema.call(params)
    end

    def validate_tip_rmt_bin_params(params)
      TipRmtBinSchema.call(params)
    end
  end
end
