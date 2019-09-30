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

    def prepare_run_allocation_targets(id)
      insert_ds = DB[<<~SQL, id]
        INSERT INTO product_resource_allocations (production_run_id, plant_resource_id)
        SELECT r.id, p.id
        FROM production_runs r
        JOIN tree_plant_resources t ON t.ancestor_plant_resource_id = r.production_line_id
        JOIN plant_resources p ON p.id = t.descendant_plant_resource_id AND p.plant_resource_type_id = (SELECT id from plant_resource_types WHERE plant_resource_type_code = 'ROBOT_BUTTON')
        WHERE r.id = ?
        AND NOT EXISTS(SELECT id FROM product_resource_allocations a WHERE a.production_run_id = r.id AND a.plant_resource_id = p.id)
      SQL

      insert_ds.insert
      ok_response
    end

    def allocate_product_setup(product_resource_allocation_id, product_setup_code)
      run_id = DB[:product_resource_allocations].where(id: product_resource_allocation_id).get(:production_run_id)
      qry = <<~SQL
        SELECT id
        FROM product_setups
        WHERE product_setup_template_id = (SELECT product_setup_template_id FROM production_runs WHERE id = #{run_id}) AND fn_product_setup_code(id) = '#{product_setup_code}'
      SQL
      product_setup_id = DB[qry].get(:id)
      update(:product_resource_allocations, product_resource_allocation_id, product_setup_id: product_setup_id)

      success_response("Allocted #{product_setup_code}", product_setup_id: product_setup_id)
    end
  end
end
