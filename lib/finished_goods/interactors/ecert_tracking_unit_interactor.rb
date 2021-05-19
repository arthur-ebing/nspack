# frozen_string_literal: true

module FinishedGoodsApp
  class EcertTrackingUnitInteractor < BaseInteractor
    def elot_preverify(params)
      res = EcertElotSchema.call(params)
      return validation_failed_response(res) if res.failure?

      service_res = nil
      repo.transaction do
        service_res = ECertPreverify.call(res)
        raise Crossbeams::InfoError, service_res.message unless service_res.success

        log_transaction
      end
      success_response(service_res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def ecert_tracking_unit_status(pallet_number)
      res = check_pallets(:exists, pallet_number)
      return res unless res.success

      res = api.tracking_unit_status(pallet_number)
      return res unless res.success

      success_response(res.message, res.instance)
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

    def api
      @api ||= ECertApi.new
    end

    def ecert_tracking_unit(id)
      repo.find_ecert_tracking_unit(id)
    end

    def validate_ecert_tracking_unit_params(params)
      EcertTrackingUnitSchema.call(params)
    end

    def check_pallets(check, pallet_numbers)
      MesscadaApp::TaskPermissionCheck::Pallets.call(check, pallet_number: pallet_numbers)
    end
  end
end
