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

    build_for_select :scrap_reasons,
                     label: :scrap_reason,
                     value: :id,
                     order_by: :scrap_reason
    build_inactive_select :scrap_reasons,
                          label: :scrap_reason,
                          value: :id,
                          order_by: :scrap_reason

    crud_calls_for :pallet_verification_failure_reasons, name: :pallet_verification_failure_reason, wrapper: PalletVerificationFailureReason
    crud_calls_for :scrap_reasons, name: :scrap_reason, wrapper: ScrapReason
  end
end
