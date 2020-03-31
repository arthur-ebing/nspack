# frozen_string_literal: true

module FinishedGoodsApp
  class EcertAgreementInteractor < BaseInteractor
    def update_agreements
      res = nil
      repo.transaction do
        res = api.update_agreements
        raise Crossbeams::InfoError, res.message unless res.success
      end
      success_response(res.message)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_ecert_agreement(id)
      name = ecert_agreement(id).code
      repo.transaction do
        repo.delete_ecert_agreement(id)
        log_status(:ecert_agreements, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted ecert agreement #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::EcertAgreement.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= EcertRepo.new
    end

    def api
      @api ||= ECertApi.new
    end

    def ecert_agreement(id)
      repo.find_ecert_agreement(id)
    end

    def validate_ecert_agreement_params(params)
      EcertAgreementSchema.call(params)
    end
  end
end
