# frozen_string_literal: true

module MasterfilesApp
  class InspectionFailureReasonRepo < BaseRepo
    build_for_select :inspection_failure_reasons,
                     label: :failure_reason,
                     value: :id,
                     order_by: :failure_reason
    build_inactive_select :inspection_failure_reasons,
                          label: :failure_reason,
                          value: :id,
                          order_by: :failure_reason

    crud_calls_for :inspection_failure_reasons, name: :inspection_failure_reason, wrapper: InspectionFailureReason
  end
end
