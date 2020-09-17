# frozen_string_literal: true

module MasterfilesApp
  class PalletVerificationFailureReasonInteractor < BaseInteractor
    def create_pallet_verification_failure_reason(params)  # rubocop:disable Metrics/AbcSize
      res = validate_pallet_verification_failure_reason_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_pallet_verification_failure_reason(res)
        log_status('pallet_verification_failure_reasons', id, 'CREATED')
        log_transaction
      end
      instance = pallet_verification_failure_reason(id)
      success_response("Created pallet verification failure reason #{instance.reason}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { reason: ['This pallet verification failure reason already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallet_verification_failure_reason(id, params)
      res = validate_pallet_verification_failure_reason_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_pallet_verification_failure_reason(id, res)
        log_transaction
      end
      instance = pallet_verification_failure_reason(id)
      success_response("Updated pallet verification failure reason #{instance.reason}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_pallet_verification_failure_reason(id)
      name = pallet_verification_failure_reason(id).reason
      repo.transaction do
        repo.delete_pallet_verification_failure_reason(id)
        log_status('pallet_verification_failure_reasons', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted pallet verification failure reason #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PalletVerificationFailureReason.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QualityRepo.new
    end

    def pallet_verification_failure_reason(id)
      repo.find_pallet_verification_failure_reason(id)
    end

    def validate_pallet_verification_failure_reason_params(params)
      PalletVerificationFailureReasonSchema.call(params)
    end
  end
end
