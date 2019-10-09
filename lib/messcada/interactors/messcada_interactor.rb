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

    def carton_labeling(params)
      res = CartonLabelingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      resource_code = res[:device]
      return failed_response("Resource Code:#{resource_code} could not be found") unless resource_code_exists?(resource_code)

      MesscadaApp::CartonLabeling.call(res)
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_verification(params)  # rubocop:disable Metrics/AbcSize
      res = CartonVerificationSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      resource_code = res[:device]
      return failed_response("Resource Code:#{resource_code} could not be found") unless resource_code_exists?(resource_code)

      carton_label_id = res[:carton_number]
      return failed_response("Carton / Bin label:#{carton_label_id} could not be found") unless carton_label_exists?(carton_label_id)

      MesscadaApp::CartonVerification.call(res)
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_verification_and_weighing(params)  # rubocop:disable Metrics/AbcSize
      res = CartonVerificationAndWeighingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      resource_code = res[:device]
      return failed_response("Resource Code:#{resource_code} could not be found") unless resource_code_exists?(resource_code)

      carton_label_id = res[:carton_number]
      return failed_response("Carton / Bin label:#{carton_label_id} could not be found") unless carton_label_exists?(carton_label_id)

      MesscadaApp::CartonVerificationAndWeighing.call(res)
    rescue StandardError => e
      failed_response(e.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def carton_verification_and_weighing_and_labeling(params)  # rubocop:disable Metrics/AbcSize
      res = CartonVerificationAndWeighingSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      resource_code = res[:device]
      return failed_response("Resource Code:#{resource_code} could not be found") unless resource_code_exists?(resource_code)

      carton_label_id = res[:carton_number]
      return failed_response("Carton / Bin label:#{carton_label_id} could not be found") unless carton_label_exists?(carton_label_id)

      MesscadaApp::CartonVerificationAndWeighingAndLabeling.call(res)
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

    def resource_code_exists?(resource_code)
      repo.resource_code_exists?(resource_code)
    end

    def carton_label_exists?(carton_label_id)
      repo.carton_label_exists?(carton_label_id)
    end
  end
end
