# frozen_string_literal: true

module MasterfilesApp
  class InspectionFailureTypeRepo < BaseRepo
    build_for_select :inspection_failure_types,
                     label: :failure_type_code,
                     value: :id,
                     order_by: :failure_type_code
    build_inactive_select :inspection_failure_types,
                          label: :failure_type_code,
                          value: :id,
                          order_by: :failure_type_code

    crud_calls_for :inspection_failure_types, name: :inspection_failure_type, wrapper: InspectionFailureType
  end
end
