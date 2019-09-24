# frozen_string_literal: true

module ProductionApp
  class ProductionRunRepo < BaseRepo
    build_for_select :production_runs,
                     label: :active_run_stage,
                     value: :id,
                     order_by: :active_run_stage
    build_inactive_select :production_runs,
                          label: :active_run_stage,
                          value: :id,
                          order_by: :active_run_stage

    crud_calls_for :production_runs, name: :production_run, wrapper: ProductionRun

    def find_production_run_with_assoc(id)
      find_with_association(:production_runs,
                            id,
                            parent_tables: [{ parent_table: :product_setup_templates,
                                              columns: [:template_name],
                                              flatten_columns: { template_name: :template_name } }],
                            lookup_functions: [{ function: :fn_production_run_code,
                                                 args: [:id],
                                                 col_name: :production_run_code }],
                            wrapper: ProductionRunFlat)
    end
  end
end
