# frozen_string_literal: true

module MesscadaApp
  class MesscadaInteractor < BaseInteractor # rubocop:disable ClassLength
    def validate_pallet_to_be_verified(pallet_number)
      pallet_sequences = find_pallet_sequences_by_pallet_number(pallet_number)
      return failed_response("scanned_pallet:#{pallet_number} doesn't exist") if pallet_sequences.empty?
      return failed_response("scanned_pallet:#{pallet_number} has already been inspected") if pallet_sequences.first[:inspected]

      success_response('pallet found', oldest_pallet_sequence_id: pallet_sequences.first[:id])
    end

    def find_pallet_sequences_by_pallet_number(pallet_number)
      repo.find_pallet_sequences_by_pallet_number(pallet_number)
    end

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

    def carton_verification(params)  # rubocop:disable Metrics/AbcSize, CyclomaticComplexity, PerceivedComplexity
      carton_and_pallet_verification = (AppConst::COMBINE_CARTON_AND_PALLET_VERIFICATION == 'true') && (params[:device].nil? ? true : false)
      params[:carton_and_pallet_verification] = carton_and_pallet_verification

      if carton_and_pallet_verification
        res = CartonAndPalletVerificationSchema.call(params)
        return validation_failed_response(res) unless res.messages.empty?
      else
        res = CartonVerificationSchema.call(params)
        return validation_failed_response(res) unless res.messages.empty?

        resource_code = res[:device]
        return failed_response("Resource Code:#{resource_code} could not be found") unless resource_code_exists?(resource_code)
      end

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

    def find_pallet_sequences_from_same_pallet(id)
      repo.find_pallet_sequences_from_same_pallet(id)
    end

    def find_pallet_sequence_attrs(id)
      repo.find_pallet_sequence_attrs(id)
    end

    def verify_pallet_sequence(pallet_sequence_id, params) # rubocop:disable Metrics/AbcSize
      return validation_failed_response(messages: { verification_failure_reason: ['is missing'] }) if params[:verification_result] == 'failed' && params[:verification_failure_reason].nil_or_empty?

      pallet_id = nil
      repo.transaction do
        pallet_id = get_pallet_sequence_pallet_id(pallet_sequence_id)
        update_pallet_sequence_verification_result(pallet_sequence_id, params)
        update_pallet_fruit_sticker_pm_product_id(pallet_id, params[:fruit_sticker_pm_product_id]) unless params[:fruit_sticker_pm_product_id].nil_or_empty?
        update_pallet_nett_weight(pallet_id) if params[:nett_weight]
      end
      verification_completed = pallet_verified?(pallet_id)
      success_response('Pallet Sequence updated successfully', verification_completed: verification_completed)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def get_pallet_sequence_pallet_id(id)
      repo.get(:pallet_sequences, id, :pallet_id)
    end

    private

    def update_pallet_sequence_verification_result(pallet_sequence_id, params)
      repo.update_pallet_sequence_verification_result(pallet_sequence_id, params)
    end

    def update_pallet_fruit_sticker_pm_product_id(pallet_id, fruit_sticker_pm_product_id)
      repo.update_pallet(pallet_id, fruit_sticker_pm_product_id: fruit_sticker_pm_product_id)
    end

    def update_pallet_nett_weight(pallet_id)
      repo.update_pallet_nett_weight(pallet_id)
    end

    def pallet_verified?(pallet_id)
      repo.pallet_verified?(pallet_id)
    end

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
