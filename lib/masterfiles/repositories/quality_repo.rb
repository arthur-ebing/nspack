# frozen_string_literal: true

module MasterfilesApp
  class QualityRepo < BaseRepo
    build_for_select :pallet_verification_failure_reasons,
                     label: :reason,
                     value: :id,
                     order_by: :reason
    build_inactive_select :pallet_verification_failure_reasons,
                          label: :reason,
                          value: :id,
                          order_by: :reason

    crud_calls_for :pallet_verification_failure_reasons, name: :pallet_verification_failure_reason, wrapper: PalletVerificationFailureReason
  end
end
