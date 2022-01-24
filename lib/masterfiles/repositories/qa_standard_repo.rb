# frozen_string_literal: true

module MasterfilesApp
  class QaStandardRepo < BaseRepo
    build_for_select :qa_standards,
                     label: :qa_standard_name,
                     value: :id,
                     order_by: :qa_standard_name
    build_inactive_select :qa_standards,
                          label: :qa_standard_name,
                          value: :id,
                          order_by: :qa_standard_name

    crud_calls_for :qa_standards, name: :qa_standard, wrapper: QaStandard
  end
end
