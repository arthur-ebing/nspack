# frozen_string_literal: true

module ProductionApp
  class ProductionRunRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    crud_calls_for :production_runs, name: :production_run, wrapper: ProductionRun
    crud_calls_for :production_run_stats, name: :production_run_stat, wrapper: ProductionRunStat
    crud_calls_for :pallet_mix_rules, name: :pallet_mix_rule, wrapper: PalletMixRule

    def for_select_production_runs_for_line(production_line_id)
      query = <<~SQL
        SELECT fn_production_run_code(id) AS production_run_code, id
        FROM production_runs
        WHERE active and production_line_id = ?
        ORDER BY id DESC
        LIMIT 10
      SQL
      DB[query, production_line_id].select_map(%i[production_run_code id])
    end

    def find_max_delivery_for_run(id)
      query = <<~SQL
        select b.rmt_delivery_id, count(b.id) as bin_count
        from production_runs r
        join rmt_bins b on b.production_run_tipped_id = r.id
        where r.id=?
        group by b.rmt_delivery_id
        order by bin_count desc
      SQL
      res = DB[query, id].first
      !res.nil? ? res[:rmt_delivery_id] : nil
    end

    def find_pallet_mix_rules_by_scope(scope)
      DB[:pallet_mix_rules].where(scope: scope).first
    end

    def find_carton_by_carton_label_id(carton_label_id)
      DB[:cartons].where(carton_label_id: carton_label_id).first
    end

    def find_pallet_by_pallet_number(pallet_number)
      DB[:pallets].where(pallet_number: pallet_number).first
    end

    def find_pallet_sequence_by_pallet_number_and_pallet_sequence_number(pallet_number, pallet_sequence_number)
      DB[:pallet_sequences].where(pallet_number: pallet_number, pallet_sequence_number: pallet_sequence_number).get(:id)
    end

    def pallet_id_from_pallet_sequence_id(pallet_sequence_id)
      get_with_args(:pallet_sequences, :pallet_id, id: pallet_sequence_id)
    end

    def get_pallet_label_data(pallet_id)
      DB[:vw_pallet_label].where(pallet_id: pallet_id).first
    end

    def find_pallet_labels
      MasterfilesApp::LabelTemplateRepo.new.for_select_label_templates(where: { application: AppConst::PRINT_APP_PALLET }).map { |nm, _| nm }
    end

    def find_pallet_label_name_by_resource_allocation_id(product_resource_allocation_id)
      qry = <<~SQL
        select ps.pallet_label_name
        from product_setups ps
        join product_resource_allocations pra on pra.product_setup_id=ps.id
        where pra.id = ?
      SQL
      pallet_label = DB[qry, product_resource_allocation_id].first
      pallet_label.nil_or_empty? ? '' : pallet_label[:pallet_label_name]
    end

    def find_pallet_sequence_attrs_by_id(id)
      qry = <<~SQL
        SELECT *
        FROM vw_pallet_sequence_flat
        WHERE id = ?
      SQL
      DB[qry, id].first
    end

    def find_pallet_sequence_attrs(pallet_id, seq_number)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE pallet_id = #{pallet_id} and pallet_sequence_number = #{seq_number}"].first
    end

    def find_carton_cpp(carton_id)
      qry = <<~SQL
        select cpp.cartons_per_pallet
        from cartons c
        join cartons_per_pallet cpp on cpp.id = c.cartons_per_pallet_id
        where c.id = ?
      SQL
      DB[qry, carton_id].first
    end

    def find_carton_with_run_info(carton_id)
      qry = <<~SQL
        select c.*, r.closed as production_run_closed
        from cartons c
        join production_runs r on r.id = c.production_run_id
        where c.id = ?
      SQL
      DB[qry, carton_id].first
    end

    def create_production_run(params)
      attrs = params.to_h
      # NOTE:The NO_RUN_ALLOCATION should be changed to come from the LINE
      attrs = attrs.merge(allocation_required: false) if ENV['NO_RUN_ALLOCATION']
      create(:production_runs, attrs)
    end

    def clone_production_run(id)
      ignore_cols = %i[id created_at updated_at active_run_stage started_at
                       closed_at re_executed_at completed_at reconfiguring
                       closed setup_complete running completed tipping labeling]

      attrs = find_hash(:production_runs, id).reject { |k, _| ignore_cols.include?(k) }
      new_id = create_production_run(attrs.merge(cloned_from_run_id: id))
      clone_alloc = <<~SQL
        INSERT INTO product_resource_allocations(production_run_id, plant_resource_id, product_setup_id, label_template_id, packing_method_id)
        SELECT #{new_id}, plant_resource_id, product_setup_id, label_template_id, packing_method_id
        FROM product_resource_allocations
        WHERE production_run_id = ?
      SQL
      DB[clone_alloc, id].insert
      new_id
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
                                               { function: :fn_current_status,
                                                 args: ['production_runs', :id],
                                                 col_name: :status },
                                               { function: :fn_production_run_code,
                                                 args: [:cloned_from_run_id],
                                                 col_name: :cloned_from_run_code }],
                            wrapper: ProductionRunFlat)
    end

    def production_run_code(id)
      DB[:production_runs].select(Sequel.lit("fn_production_run_code(#{id}) AS production_run_code")).where(id: id).first[:production_run_code]
    end

    def prepare_run_allocation_targets(id)
      default_packing_method_id = MasterfilesApp::PackagingRepo.new.find_packing_method_by_code(AppConst::DEFAULT_PACKING_METHOD)&.id
      raise Crossbeams::FrameworkError, "Default Packing Method: #{AppConst::DEFAULT_PACKING_METHOD} does not exist." if default_packing_method_id.nil_or_empty?

      insert_ds = DB[<<~SQL, id]
        INSERT INTO product_resource_allocations (production_run_id, plant_resource_id, packing_method_id)
        SELECT r.id, p.id, #{default_packing_method_id}
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

    def packing_method_for_allocation(product_resource_allocation_id, packing_method_code)
      packing_method_id = MasterfilesApp::PackagingRepo.new.find_packing_method_by_code(packing_method_code)&.id
      raise Crossbeams::FrameworkError, "Packing Method: #{packing_method_code} does not exist." if packing_method_id.nil_or_empty?

      update(:product_resource_allocations, product_resource_allocation_id, packing_method_id: packing_method_id)

      success_response("Applied #{packing_method_code}", packing_method_code: packing_method_code)
    end

    def copy_allocations_for_run(product_resource_allocation_id, allocation_ids, product_setup_id, label_template_id)
      xtra = label_template_id.nil? ? '' : ", label_template_id = #{label_template_id}"
      qry = <<~SQL
        UPDATE product_resource_allocations
        SET product_setup_id = #{product_setup_id} #{xtra}
        WHERE id IN (#{allocation_ids.join(', ')})
          AND id <> #{product_resource_allocation_id}
      SQL
      DB[qry].update
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
               a.product_setup_id, a.label_template_id, s.system_resource_code, t.label_template_name, a.packing_method_id
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

    # Does the run have at least one resource allocation with a setup and label?
    def any_allocated_setup?(id)
      exists?(:product_resource_allocations, Sequel.lit("production_run_id = #{id} AND product_setup_id IS NOT NULL AND label_template_id IS NOT NULL"))
    end

    # Is there an active tipping run on this line?
    def line_has_active_tipping_run?(production_line_id)
      DB[:production_runs].where(production_line_id: production_line_id, running: true, tipping: true).count.positive?
    end

    def tipping_run_for_line(production_run_id, production_line_id)
      DB[:production_runs]
        .where(production_line_id: production_line_id)
        .where(running: true)
        .where(tipping: true)
        .exclude(id: production_run_id)
        .get(:id)
    end

    # For a production run, a list of line resources and which (if any) product spec is allocated.
    def button_allocations(production_run_id)
      query = <<~SQL
        SELECT
        "sysres"."system_resource_code" AS module,
        REPLACE("btns"."system_resource_code", "sysres"."system_resource_code" || '-', '') AS button,
        "a"."product_setup_id", "a"."label_template_id",
        "commodities"."code" AS commodity_code,
        "marketing_varieties"."marketing_variety_code",
        "standard_pack_codes"."standard_pack_code",
        "basic_pack_codes"."basic_pack_code",
        "std_fruit_size_counts"."size_count_value",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "fruit_size_references"."size_reference",
        "marks"."mark_code",
        "target_market_groups"."target_market_group_name",
        "organizations"."short_description" AS org_code
        FROM "production_runs" r
        JOIN "tree_plant_resources" t ON "t"."ancestor_plant_resource_id" = "r"."production_line_id"
        JOIN "plant_resources" p ON "p"."id" = "t"."descendant_plant_resource_id" AND "p"."plant_resource_type_id" = (SELECT
          "id"
          FROM "plant_resource_types"
          WHERE "plant_resource_type_code" = 'ROBOT_BUTTON')
        LEFT JOIN "system_resources" btns ON "btns"."id" = "p"."system_resource_id"
        LEFT JOIN "product_resource_allocations" a ON "a"."production_run_id" = "r"."id" AND "a"."plant_resource_id" = "p"."id"
        LEFT JOIN "product_setups" ON "product_setups"."id" = "a"."product_setup_id"
        LEFT JOIN "tree_plant_resources" tpl ON "tpl"."descendant_plant_resource_id" = "p"."id" AND "tpl"."path_length" = 1
        LEFT JOIN "plant_resources" parent ON "parent"."id" = "tpl"."ancestor_plant_resource_id"
        LEFT JOIN "system_resources" sysres ON "sysres"."id" = "parent"."system_resource_id"

        LEFT JOIN "marketing_varieties" ON "marketing_varieties"."id" = "product_setups"."marketing_variety_id"
        LEFT JOIN "std_fruit_size_counts" ON "std_fruit_size_counts"."id" = "product_setups"."std_fruit_size_count_id"
        LEFT JOIN "commodities" ON "commodities"."id" = "std_fruit_size_counts"."commodity_id"
        LEFT JOIN "basic_pack_codes" ON "basic_pack_codes"."id" = "product_setups"."basic_pack_code_id"
        LEFT JOIN "standard_pack_codes" ON "standard_pack_codes"."id" = "product_setups"."standard_pack_code_id"
        LEFT JOIN "fruit_actual_counts_for_packs" ON "fruit_actual_counts_for_packs"."id" =
        "product_setups"."fruit_actual_counts_for_pack_id"
        LEFT JOIN "fruit_size_references" ON "fruit_size_references"."id" = "product_setups"."fruit_size_reference_id"
        LEFT JOIN "party_roles" ON "party_roles"."id" = "product_setups"."marketing_org_party_role_id"
        LEFT JOIN "organizations" ON "organizations"."id" = "party_roles"."organization_id"
        LEFT JOIN "target_market_groups" ON "target_market_groups"."id" = "product_setups"."packed_tm_group_id"
        LEFT JOIN "marks" ON "marks"."id" = "product_setups"."mark_id"

        WHERE r.id = ?
        ORDER BY "btns"."system_resource_code"
      SQL

      DB[query, production_run_id].all
    end

    def bin_verification_settings(production_run_id)
      # Get the BVMs from the prod run packhouse and each of the below...
      query = <<~SQL
        SELECT plant_resource_button_indicator, material_mass
        FROM public.standard_pack_codes
        WHERE plant_resource_button_indicator IS NOT NULL
        ORDER BY plant_resource_button_indicator
      SQL
      buttons = DB[query].select_map(%i[plant_resource_button_indicator material_mass])
      return {} if buttons.empty?

      query = <<~SQL
        SELECT "sysres"."system_resource_code" AS module
        FROM "production_runs" r
        JOIN "tree_plant_resources" t ON "t"."ancestor_plant_resource_id" = "r"."packhouse_resource_id"
        JOIN "plant_resources" p ON "p"."id" = "t"."descendant_plant_resource_id"
          AND "p"."plant_resource_type_id" = (SELECT "id"
              FROM "plant_resource_types"
              WHERE "plant_resource_type_code" = 'BIN_VERIFICATION_ROBOT')
        LEFT JOIN "system_resources" sysres ON "sysres"."id" = "p"."system_resource_id"
        WHERE r.id = ?
        ORDER BY "sysres"."system_resource_code"
      SQL
      modules = DB[query, production_run_id].select_map(:module)
      return {} if modules.empty?

      grp = {}
      modules.each { |mod| grp[mod] = buttons }
      grp
    end
  end
end
