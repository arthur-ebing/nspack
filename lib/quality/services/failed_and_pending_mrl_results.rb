# frozen_string_literal: true

module QualityApp
  class FailedAndPendingMrlResults < BaseService
    attr_reader :repo, :rmt_delivery_id, :match_grade, :match_packed_tm_group

    def initialize(rmt_delivery_id)
      @rmt_delivery_id = rmt_delivery_id
      @repo = MrlResultRepo.new
    end

    def call
      res = MrlResultDeliverySchema.call({ rmt_delivery_id: rmt_delivery_id })
      return validation_failed_response(res) if res.failure?

      check_errors
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def check_errors # rubocop:disable Metrics/AbcSize
      farm_id, cultivar_id, season_id = repo.get_value(:rmt_deliveries, %i[farm_id cultivar_id season_id], id: rmt_delivery_id)
      mrl_result_ids = repo.select_values(:mrl_results, :id, farm_id: farm_id, cultivar_id: cultivar_id, season_id: season_id)
      return success_response('Delivery has passed Mrl Results.', { rmt_delivery_id: rmt_delivery_id }) if mrl_result_ids.nil_or_empty?

      passed = repo.check_mrl_results_status(mrl_result_ids,
                                             where: { mrl_sample_passed: true, max_num_chemicals_passed: true },
                                             exclude: { result_received_at: nil })
      return success_response('Delivery has passed Mrl Results.', { rmt_delivery_id: rmt_delivery_id }) if passed

      failed = repo.check_mrl_results_status(mrl_result_ids,
                                             where: { mrl_sample_passed: false },
                                             exclude: { result_received_at: nil })
      errors = if failed
                 { failed: true, pending: false }
               else
                 { failed: false, pending: false }
               end
      OpenStruct.new(success: false,
                     instance: { rmt_delivery_id: rmt_delivery_id },
                     errors: errors,
                     message: "Delivery #{rmt_delivery_id} has #{errors[:failed] ? 'failed' : 'pending'} Mrl Results")
    end
  end
end
