# frozen_string_literal: true

module MasterfilesApp
  class QaStandardTypeRepo < BaseRepo
    build_for_select :qa_standard_types,
                     label: :qa_standard_type_code,
                     value: :id,
                     order_by: :qa_standard_type_code
    build_inactive_select :qa_standard_types,
                          label: :qa_standard_type_code,
                          value: :id,
                          order_by: :qa_standard_type_code

    crud_calls_for :qa_standard_types, name: :qa_standard_type, wrapper: QaStandardType
  end
end
