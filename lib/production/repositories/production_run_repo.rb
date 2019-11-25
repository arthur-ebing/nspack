# frozen_string_literal: true

module ProductionApp
  class ProductionRunRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :production_runs, name: :production_run, wrapper: ProductionRun
    crud_calls_for :production_run_stats, name: :production_run_stat, wrapper: ProductionRunStat

    def create_production_run(params)
      attrs = params.to_h
      # NOTE:The NO_RUN_ALLOCATION should be changed to come from the LINE
      attrs = attrs.merge(allocation_required: false) if ENV['NO_RUN_ALLOCATION']
      create(:production_runs, attrs)
    end

    def create_production_run_stats(id)
      create(:production_run_stats, production_run_id: id)
    end

    def delete_product_resource_allocations(production_run_id)
      DB[:product_resource_allocations].where(production_run_id: production_run_id).delete
    end

    def delete_production_run_stats(id)
      DB[:production_run_stats].where(production_run_id: id).delete
    end

    def find_production_run_flat(id)
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
                                                 col_name: :production_run_code },
                                               { function: :fn_production_run_code,
                                                 args: [:cloned_from_run_id],
                                                 col_name: :cloned_from_run_code }],
                            wrapper: ProductionRunFlat)
    end

    def production_run_code(id)
      DB[:production_runs].select(Sequel.lit("fn_production_run_code(#{id}) AS production_run_code")).where(id: id).first[:production_run_code]
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

    def label_for_allocation(product_resource_allocation_id, label_template_name)
      label_template_id = MasterfilesApp::LabelTemplateRepo.new.find_label_template_by_name(label_template_name)&.id
      update(:product_resource_allocations, product_resource_allocation_id, label_template_id: label_template_id)

      success_response("Applied #{label_template_name}", label_template_name: label_template_name)
    end

    # Find Production runs on a line in various states (tipping/labeling)
    def find_production_runs_for_line_in_state(line_id, running: true, tipping: nil, labeling: nil)
      ds = DB[:production_runs].where(production_line_id: line_id).where(running: running)
      ds = ds.where(tipping: tipping) unless tipping.nil?
      ds = ds.where(labeling: true) unless labeling.nil?

      runs = ds.select_map(:id)
      return failed_response('No runs in this state') if runs.empty?

      success_response('ok', runs)
    end

    def for_select_labeling_run_lines
      DB[:production_runs]
        .join(:plant_resources, id: :production_line_id)
        .where(running: true)
        .where(labeling: true)
        .select_map([:plant_resource_code, Sequel[:production_runs][:id]])
    end

    def labeling_run_for_line(production_line_id)
      DB[:production_runs]
        .where(production_line_id: production_line_id)
        .where(running: true)
        .where(labeling: true)
        .get(:id)
    end

    def allocated_setup_keys(production_run_id)
      query = <<~SQL
        SELECT a.id AS product_resource_allocation_id, plant_resource_id AS resource_id,
               a.product_setup_id, a.label_template_id, s.system_resource_code, t.label_template_name
          FROM product_resource_allocations a
          JOIN plant_resources p ON p.id = a.plant_resource_id
          JOIN system_resources s ON s.id = p.system_resource_id
          JOIN label_templates t ON t.id = a.label_template_id
          WHERE a.production_run_id = ?
            AND a.active
            AND a.product_setup_id IS NOT NULL
            AND a.label_template_id IS NOT NULL
      SQL
      recs = DB[query, production_run_id].all
      recs.map do |rec|
        rec.merge(setup_data: setup_data_for(rec[:product_setup_id]))
      end
    end

    def setup_data_for(product_setup_id)
      rec = find_hash(:product_setups, product_setup_id)
      rec[:treatment_ids] = rec[:treatment_ids]&.to_ary # convert treatment_ids from Sequel array to ruby array
      rec
    end

    # Does the run have at least one resource allocation with a setup?
    def any_allocated_setup?(id)
      exists?(:product_resource_allocations, Sequel.lit("production_run_id = #{id} AND product_setup_id IS NOT NULL"))
    end

    # Is there an active tipping run on this line?
    def line_has_active_tipping_run?(production_line_id)
      DB[:production_runs].where(production_line_id: production_line_id, running: true, tipping: true).count.positive?
    end
  end
end
