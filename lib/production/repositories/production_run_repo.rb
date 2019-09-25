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
                                              flatten_columns: { template_name: :template_name } },
                                            { parent_table: :cultivar_groups,
                                              columns: [:cultivar_group_code],
                                              flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                            { parent_table: :cultivars,
                                              columns: [:cultivar_name],
                                              flatten_columns: { cultivar_name: :cultivar_name } },
                                            { parent_table: :farms,
                                              columns: [:farm_code],
                                              flatten_columns: { farm_code: :farm_code } },
                                            { parent_table: :pucs,
                                              columns: [:puc_code],
                                              flatten_columns: { puc_code: :puc_code } },
                                            { parent_table: :orchards,
                                              columns: [:orchard_code],
                                              flatten_columns: { orchard_code: :orchard_code } },
                                            { parent_table: :seasons,
                                              columns: [:season_code],
                                              flatten_columns: { season_code: :season_code } },
                                            { parent_table: :plant_resources,
                                              foreign_key: :packhouse_resource_id,
                                              columns: [:plant_resource_code],
                                              flatten_columns: { plant_resource_code: :packhouse_code } },
                                            { parent_table: :plant_resources,
                                              foreign_key: :production_line_id,
                                              columns: [:plant_resource_code],
                                              flatten_columns: { plant_resource_code: :line_code } }],
                            lookup_functions: [{ function: :fn_production_run_code,
                                                 args: [:id],
                                                 col_name: :production_run_code }],
                            wrapper: ProductionRunFlat)
    end
  end
end
