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

    build_for_select :contract_workers,
                     label: :full_names,
                     value: :id,
                     order_by: :full_names
    build_inactive_select :contract_workers,
                          label: :full_names,
                          value: :id,
                          order_by: :full_names

    crud_calls_for :contract_workers, name: :contract_worker, wrapper: ContractWorker

    def find_contract_worker(id)
      find_with_association(:contract_workers, id,
                            wrapper: ContractWorker,
                            parent_tables: [{ parent_table: :employment_types,
                                              columns: [:code],
                                              flatten_columns: { code: :employer_type_code } },
                                            { parent_table: :contract_types,
                                              columns: [:code],
                                              flatten_columns: { code: :contract_type_code } },
                                            { parent_table: :wage_levels,
                                              columns: [:wage_level],
                                              flatten_columns: { wage_level: :wage_level } }])
    end
  end
end
