# frozen_string_literal: true

module FinishedGoodsApp
  class EcertTrackingUnitInteractor < BaseInteractor
    def elot_preverify(params) # rubocop:disable Metrics/AbcSize
      res = EcertElotSchema.call(params)
      return validation_failed_response(res) unless res.messages.empty?

      service_res = nil
      repo.transaction do
        service_res = ECertPreverify.call(res.to_h)
        raise Crossbeams::InfoError, service_res.message unless service_res.success

        log_transaction
      end
      success_response(service_res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_ecert_tracking_unit(id)
      name = ecert_tracking_unit(id).industry
      repo.transaction do
        repo.delete_ecert_tracking_unit(id)
        log_status(:ecert_tracking_units, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted ecert tracking unit #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::EcertTrackingUnit.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= EcertRepo.new
    end

    def ecert_tracking_unit(id)
      repo.find_ecert_tracking_unit(id)
    end

    def validate_ecert_tracking_unit_params(params)
      EcertTrackingUnitSchema.call(params)
    end
  end
end
