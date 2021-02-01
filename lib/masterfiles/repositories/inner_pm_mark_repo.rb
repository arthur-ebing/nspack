# frozen_string_literal: true

module MasterfilesApp
  class InnerPmMarkRepo < BaseRepo
    build_for_select :inner_pm_marks,
                     label: :description,
                     value: :id,
                     no_active_check: true,
                     order_by: :description

    crud_calls_for :inner_pm_marks, name: :inner_pm_mark, wrapper: InnerPmMark
  end
end
