# frozen_string_literal: true

module MasterfilesApp
  class HumanResourcesRepo < BaseRepo
    build_for_select :employment_types,
                     label: :code,
                     value: :id,
                     no_active_check: true,
                     order_by: :code

    crud_calls_for :employment_types, name: :employment_type, wrapper: EmploymentType

    build_for_select :contract_types,
                     label: :code,
                     value: :id,
                     no_active_check: true,
                     order_by: :code

    crud_calls_for :contract_types, name: :contract_type, wrapper: ContractType

    build_for_select :wage_levels,
                     label: :description,
                     value: :id,
                     no_active_check: true,
                     order_by: :description

    crud_calls_for :wage_levels, name: :wage_level, wrapper: WageLevel
  end
end
