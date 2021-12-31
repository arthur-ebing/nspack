# frozen_string_literal: true

module ProductionApp
  class ProductionRunRepo < BaseRepo
    crud_calls_for :production_runs, name: :production_run, wrapper: ProductionRun
    crud_calls_for :production_run_stats, name: :production_run_stat, wrapper: ProductionRunStat
    crud_calls_for :pallet_mix_rules, name: :pallet_mix_rule, wrapper: PalletMixRule
    crud_calls_for :product_resource_allocations, name: :product_resource_allocation, wrapper: ProductResourceAllocation

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

    def find_pallets_sequences(pallet_number)
      DB[:pallet_sequences].where(pallet_number: pallet_number).all.sort_by { |p| p[:id] }
    end

    def find_pallet_mix_rule_flat(id)
      find_with_association(:pallet_mix_rules,
                            id,
                            parent_tables: [{ parent_table: :plant_resources,
                                              foreign_key: :packhouse_plant_resource_id,
                                              columns: [:plant_resource_code],
                                              flatten_columns: { plant_resource_code: :packhouse_code } }],
                            wrapper: PalletMixRuleFlat)
    end

    def all_production_runs
      query = <<~SQL
        SELECT fn_production_run_code(production_runs.id) AS production_run_code, production_runs.id
        FROM production_runs
      SQL
      DB[query].all.map { |r| [r[:production_run_code], r[:id]] }
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
      get(:pallet_sequences, :pallet_id, pallet_sequence_id)
    end

    def first_sequence_id_from_pallet(pallet_id)
      get(:pallet_sequences, :id, pallet_id)
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
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.id = ?')
      DB[query, id].first
    end

    def find_carton_label_attrs_by_id(id)
      query = MesscadaApp::DatasetCartonLabel.call('WHERE carton_labels.id = ?')
      DB[query, id].first
    end

    def find_pallet_sequence_attrs(pallet_id, seq_number)
      filters = ['WHERE pallet_sequences.pallet_id = ?']
      filters << '  AND pallet_sequences.pallet_sequence_number = ?'
      query = MesscadaApp::DatasetPalletSequence.call(filters)
      DB[query, pallet_id, seq_number].first
    end

    def find_carton_cpp(carton_id)
      qry = <<~SQL
        select cpp.cartons_per_pallet
        from cartons c
        join carton_labels cl on cl.id = c.carton_label_id
        join cartons_per_pallet cpp on cpp.id = cl.cartons_per_pallet_id
        where c.id = ?
      SQL
      DB[qry, carton_id].first
    end

    def find_carton_with_run_info(carton_id)
      qry = <<~SQL
        select c.*, r.closed as production_run_closed
        from cartons c
        join carton_labels cl on cl.id = c.carton_label_id
        join production_runs r on r.id = cl.production_run_id
        where c.id = ?
      SQL
      DB[qry, carton_id].first
    end

    def increment_sequence(pallet_sequence_id)
      query = <<~SQL
        UPDATE pallet_sequences
        SET carton_quantity = carton_quantity + 1
        WHERE id = #{pallet_sequence_id}
      SQL
      DB.execute(query)
    end

    def decrement_sequence(pallet_sequence_id)
      query = <<~SQL
        UPDATE pallet_sequences
        SET carton_quantity = carton_quantity - 1
        WHERE id = #{pallet_sequence_id}
      SQL
      DB.execute(query)
    end

    def increment_sequence_by(increment, pallet_sequence_id)
      DB[:pallet_sequences].where(id: pallet_sequence_id).update(carton_quantity: Sequel.lit('carton_quantity + ?', increment))
    end

    def decrement_sequence_by(decrement, pallet_sequence_id)
      DB[:pallet_sequences].where(id: pallet_sequence_id).update(carton_quantity: Sequel.lit('carton_quantity - ?', decrement))
    end

    def create_production_run(params)
      attrs = params.to_h
      attrs = attrs.merge(allocation_required: false) if AppConst::CR_PROD.no_run_allocations?(production_line_id: params[:production_line_id])
      create(:production_runs, attrs)
    end

    def clone_production_run(id)
      ignore_cols = %i[id created_at updated_at active_run_stage started_at
                       closed_at re_executed_at completed_at reconfiguring
                       closed setup_complete running completed tipping labeling]

      attrs = find_hash(:production_runs, id).reject { |k, _| ignore_cols.include?(k) }
      new_id = create_production_run(attrs.merge(cloned_from_run_id: id))
      clone_alloc = <<~SQL
        INSERT INTO product_resource_allocations(production_run_id, plant_resource_id, product_setup_id,
                    label_template_id, packing_method_id, packing_specification_item_id, target_customer_party_role_id,
                    work_order_item_id)
        SELECT #{new_id}, plant_resource_id, product_setup_id, label_template_id, packing_method_id, packing_specification_item_id,
               target_customer_party_role_id, work_order_item_id
        FROM product_resource_allocations
        WHERE production_run_id = ?
      SQL
      DB[clone_alloc, id].insert
      new_id
    end

    def inactive_labels_on_run(production_run_id)
      DB[:label_templates].where(id: DB[:product_resource_allocations]
                                       .where(production_run_id: production_run_id)
                                       .exclude(label_template_id: nil)
                                       .select_map(:label_template_id),
                                 active: false)
                          .select_map(:label_template_name).uniq
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
      hash = find_with_association(
        :production_runs, id,
        parent_tables: [{ parent_table: :product_setup_templates,
                          flatten_columns: { template_name: :template_name } },
                        { parent_table: :cultivar_groups,
                          flatten_columns: { cultivar_group_code: :cultivar_group_code, commodity_id: :commodity_id } },
                        { parent_table: :cultivars,
                          flatten_columns: { cultivar_name: :cultivar_name } },
                        { parent_table: :commodities, foreign_key: :commodity_id,
                          flatten_columns: { code: :commodity_code } },
                        { parent_table: :farms,
                          flatten_columns: { farm_code: :farm_code } },
                        { parent_table: :pucs,
                          flatten_columns: { puc_code: :puc_code } },
                        { parent_table: :orchards,
                          flatten_columns: { orchard_code: :orchard_code } },
                        { parent_table: :seasons,
                          flatten_columns: { season_code: :season_code } },
                        { parent_table: :rmt_sizes,
                          flatten_columns: { size_code: :size_code } },
                        { parent_table: :rmt_codes,
                          flatten_columns: { rmt_code: :rmt_code } },
                        { parent_table: :rmt_classes,
                          flatten_columns: { rmt_class_code: :class_code } },
                        { parent_table: :colour_percentages,
                          flatten_columns: { colour_percentage: :colour_percentage } },
                        { parent_table: :treatments, foreign_key: :actual_cold_treatment_id,
                          flatten_columns: { treatment_code: :actual_cold_treatment_code } },
                        { parent_table: :treatments, foreign_key: :actual_ripeness_treatment_id,
                          flatten_columns: { treatment_code: :actual_ripeness_treatment_code } },
                        { parent_table: :plant_resources, foreign_key: :packhouse_resource_id,
                          flatten_columns: { plant_resource_code: :packhouse_code } },
                        { parent_table: :plant_resources, foreign_key: :production_line_id,
                          flatten_columns: { plant_resource_code: :line_code } }],
        lookup_functions: [{ function: :fn_production_run_code,
                             args: [:id],
                             col_name: :production_run_code },
                           { function: :fn_current_status,
                             args: ['production_runs', :id],
                             col_name: :status },
                           { function: :fn_production_run_code,
                             args: [:cloned_from_run_id],
                             col_name: :cloned_from_run_code }]
      )
      return nil if hash.nil?

      ProductionRunFlat.new(hash)
    end

    def find_product_resource_allocation_flat(id)
      find_with_association(:product_resource_allocations,
                            id,
                            parent_tables: [{ parent_table: :label_templates,
                                              columns: [:label_template_name],
                                              flatten_columns: { label_template_name: :label_template_name } },
                                            { parent_table: :packing_methods,
                                              columns: [:packing_method_code],
                                              flatten_columns: { packing_method_code: :packing_method_code } }],
                            lookup_functions: [{ function: :fn_product_setup_code,
                                                 args: [:product_setup_id],
                                                 col_name: :product_setup_code },
                                               { function: :fn_party_role_name,
                                                 args: [:target_customer_party_role_id],
                                                 col_name: :target_customer },
                                               { function: :fn_packing_specification_code,
                                                 args: [:packing_specification_item_id],
                                                 col_name: :packing_specification_item_code }],
                            wrapper: ProductResourceAllocationFlat)
    end

    def production_run_code(id)
      DB[:production_runs].select(Sequel.lit("fn_production_run_code(#{id}) AS production_run_code")).where(id: id).first[:production_run_code]
    end

    def target_market_ids_for_run(id)
      DB[:product_resource_allocations]
        .join(:product_setups, id: :product_setup_id)
        .where(production_run_id: id)
        .exclude(label_template_id: nil)
        .distinct
        .select_map(:packed_tm_group_id)
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
      # use another type for packpoint-button?
      # Crossbeams::Config::ResourceDefinitions::ROBOT_BUTTON

      # Also insert if client rule && type is packpoint
      if AppConst::CR_PROD.print_from_line_scanning
        insert_ds = DB[<<~SQL, id]
          INSERT INTO product_resource_allocations (production_run_id, plant_resource_id, packing_method_id)
          SELECT r.id, p.id, #{default_packing_method_id}
          FROM production_runs r
          JOIN tree_plant_resources t ON t.ancestor_plant_resource_id = r.production_line_id
          JOIN plant_resources p ON p.id = t.descendant_plant_resource_id
          JOIN plant_resource_types prt ON prt.id = p.plant_resource_type_id AND prt.packpoint
          WHERE r.id = ?
          AND NOT EXISTS(SELECT id FROM product_resource_allocations a WHERE a.production_run_id = r.id AND a.plant_resource_id = p.id)
        SQL
        insert_ds.insert
      end

      ok_response
    end

    def allocate_product_setup(product_resource_allocation_id, product_setup_code)
      run_id = DB[:product_resource_allocations].where(id: product_resource_allocation_id).get(:production_run_id)
      qry = <<~SQL
        SELECT id, carton_label_template_id, rebin
        FROM product_setups
        WHERE product_setup_template_id = (SELECT product_setup_template_id FROM production_runs WHERE id = #{run_id}) AND fn_product_setup_code(id) = '#{product_setup_code}'
      SQL
      product_setup_id, label_template_id, rebin = DB[qry].get(%i[id carton_label_template_id rebin])
      attrs = { product_setup_id: product_setup_id }
      attrs[:label_template_id] = label_template_id unless label_template_id.nil?
      update(:product_resource_allocations, product_resource_allocation_id, attrs)

      success_response("Allocated #{product_setup_code}", product_setup_id: product_setup_id, colour_rule: rebin ? 'orange' : nil)
    end

    def allocate_packing_specification(product_resource_allocation_id, packing_specification_item_code)
      run_id = DB[:product_resource_allocations].where(id: product_resource_allocation_id).get(:production_run_id)
      qry = <<~SQL
        SELECT packing_specification_items.id, product_setup_id, product_setups.carton_label_template_id, rebin
        FROM packing_specification_items
        JOIN product_setups ON product_setups.id = packing_specification_items.product_setup_id
        WHERE product_setup_template_id = (SELECT product_setup_template_id FROM production_runs WHERE id = #{run_id})
         AND fn_packing_specification_code(packing_specification_items.id) = '#{packing_specification_item_code}'
      SQL
      spec_id, setup_id, label_template_id, rebin = DB[qry].get(%i[id product_setup_id carton_label_template_id rebin])
      attrs = { packing_specification_item_id: spec_id, product_setup_id: setup_id }
      attrs[:label_template_id] = label_template_id unless label_template_id.nil?
      update(:product_resource_allocations, product_resource_allocation_id, attrs)

      success_response("Allocated #{packing_specification_item_code}", packing_specification_item_code: packing_specification_item_code, colour_rule: rebin ? 'orange' : nil)
    end

    def automatically_allocate_work_order_item(product_resource_allocation_id)
      # Only auto-allocate if there is zero or exactly one matching item (otherwise the user has to choose the match)
      items = work_order_items_for(product_resource_allocation_id)
      return if items.count > 1

      allocate_work_order_item(product_resource_allocation_id, items.first)
    end

    def work_order_items_for(product_resource_allocation_id)
      setup_id, target_cust_id = DB[:product_resource_allocations]
                                 .where(id: product_resource_allocation_id)
                                 .get(%i[product_setup_id target_customer_party_role_id])
      ds = DB[:work_order_items]
           .join(:work_orders, id: Sequel[:work_order_items][:work_order_id])
           .left_join(:marketing_orders, id: :marketing_order_id)
           .where(product_setup_id: setup_id)
      ds = ds.where(customer_party_role_id: target_cust_id) unless target_cust_id.nil?
      ds.select_map(Sequel.function(:fn_work_order_item_code, Sequel[:work_order_items][:id])).sort
    end

    def allocate_work_order_item(product_resource_allocation_id, work_order_item_code)
      work_order_item_id = work_order_item_id_for(product_resource_allocation_id, work_order_item_code)
      update(:product_resource_allocations, product_resource_allocation_id, work_order_item_id: work_order_item_id)

      success_response("Allocated #{work_order_item_code}", work_order_item_code: work_order_item_code)
    end

    def work_order_item_id_for(product_resource_allocation_id, work_order_item_code)
      product_setup_id = DB[:product_resource_allocations].where(id: product_resource_allocation_id).get(:product_setup_id)
      DB[:work_order_items]
        .where(product_setup_id: product_setup_id, Sequel.function(:fn_work_order_item_code, :id) => work_order_item_code)
        .get(:id)
    end

    def work_order_item_code_for(product_resource_allocation_id)
      work_order_item_id = DB[:product_resource_allocations].where(id: product_resource_allocation_id).get(:work_order_item_id)
      DB.get(Sequel.function(:fn_work_order_item_code, work_order_item_id))
    end

    def resource_allocation_label_name(product_resource_allocation_id)
      DB[:label_templates].where(id: DB[:product_resource_allocations]
                                       .where(id: product_resource_allocation_id)
                                       .get(:label_template_id))
                          .get(:label_template_name)
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

    def allocate_target_customer(product_resource_allocation_id, target_customer)
      target_customer_id = MasterfilesApp::PartyRepo.new.find_party_role_from_party_name_for_role(target_customer, AppConst::ROLE_TARGET_CUSTOMER)
      raise Crossbeams::FrameworkError, "Target Customer: #{target_customer} does not exist." if target_customer_id.nil_or_empty?

      update(:product_resource_allocations, product_resource_allocation_id, target_customer_party_role_id: target_customer_id)

      success_response("Allocated Target Customer #{target_customer}", target_customer: target_customer)
    end

    def copy_allocations_for_run(product_resource_allocation_id, allocation_ids, product_setup_id, args)
      xtra = []
      xtra << ", label_template_id = #{args[:label_template_id]}" unless args[:label_template_id].to_s.nil_or_empty?

      use_packing_specs = AppConst::CR_PROD.use_packing_specifications?
      use_packing_specs = false if args[:packing_specification_item_id].to_s.nil_or_empty?
      xtra << ", packing_specification_item_id = #{args[:packing_specification_item_id]}" if use_packing_specs

      qry = <<~SQL
        UPDATE product_resource_allocations
        SET product_setup_id = #{product_setup_id} #{xtra.join('')}
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
               a.product_setup_id, a.label_template_id, COALESCE(s.system_resource_code, p.plant_resource_code) AS device_or_packpoint,
               t.label_template_name, a.packing_method_id, a.packing_specification_item_id, a.target_customer_party_role_id, a.work_order_item_id
          FROM product_resource_allocations a
          JOIN plant_resources p ON p.id = a.plant_resource_id
          LEFT JOIN system_resources s ON s.id = p.system_resource_id
          JOIN label_templates t ON t.id = a.label_template_id
          WHERE a.production_run_id = ?
            AND a.active
            AND a.product_setup_id IS NOT NULL
            AND a.label_template_id IS NOT NULL
      SQL
      recs = DB[query, production_run_id].all
      recs.map do |rec|
        packing_spec = packing_specification_keys(rec[:packing_specification_item_id])
        rec.merge(setup_data: setup_data_for(rec[:product_setup_id]).to_h.merge(packing_spec))
      end
    end

    def packing_specification_keys(packing_specification_item_id)
      lookup_packing_specs = AppConst::CR_PROD.use_packing_specifications?
      lookup_packing_specs = false if packing_specification_item_id.to_s.nil_or_empty?

      attrs = { packing_specification_item_id: nil,
                tu_labour_product_id: nil,
                ru_labour_product_id: nil,
                pm_mark_id: nil,
                fruit_sticker_ids: nil,
                tu_sticker_ids: nil,
                pm_bom_id: nil }
      return attrs unless lookup_packing_specs

      query = <<~SQL
        SELECT psi.id AS packing_specification_item_id, psi.tu_labour_product_id, psi.ru_labour_product_id,
               psi.pm_mark_id, psi.fruit_sticker_ids, psi.tu_sticker_ids, psi.pm_bom_id
          FROM packing_specification_items psi
          WHERE psi.id = ?
      SQL
      rec = DB[query, packing_specification_item_id].first
      return attrs if rec.nil?

      rec[:fruit_sticker_ids] = rec[:fruit_sticker_ids]&.to_ary
      rec[:tu_sticker_ids] = rec[:tu_sticker_ids]&.to_ary
      rec
    end

    def setup_data_for(product_setup_id)
      rec = find_hash(:product_setups, product_setup_id)
      rec[:treatment_ids] = rec[:treatment_ids]&.to_ary # convert treatment_ids from Sequel array to ruby array
      rec[:rmt_container_material_owner_id] = get_value(:standard_pack_codes, :rmt_container_material_owner_id, id: rec[:standard_pack_code_id])
      rec
    end

    def resolve_setup_cultivar_id(product_setup_id)
      args = DB[:product_setups].where(id: product_setup_id).select(:product_setup_template_id, :marketing_variety_id).first
      cultivar_id = DB[:product_setup_templates].where(id: args[:product_setup_template_id]).get(:cultivar_id)
      return cultivar_id unless cultivar_id.nil?

      cultivar_ids = DB[:marketing_varieties_for_cultivars].where(marketing_variety_id: args[:marketing_variety_id]).select_map(:cultivar_id).uniq
      return nil unless cultivar_ids.count == 1

      cultivar_ids.first
    end

    # Does the run have at least one resource allocation with a setup and label?
    def any_allocated_setup?(id)
      exists?(:product_resource_allocations, Sequel.lit("production_run_id = #{id} AND product_setup_id IS NOT NULL AND label_template_id IS NOT NULL"))
    end

    def for_select_product_setups_for_allocation(product_resource_allocation_id)
      run_id = get_value(:product_resource_allocations, :production_run_id, id: product_resource_allocation_id)
      query = <<~SQL
        SELECT fn_product_setup_code(id) AS code, id
        FROM product_setups
        WHERE product_setup_template_id = (SELECT product_setup_template_id
                                           FROM production_runs
                                           WHERE id = ?)
        ORDER BY 1
      SQL
      DB[query, run_id].select_map(%i[code id])
    end

    def for_select_packing_specification_items_for_allocation(product_resource_allocation_id)
      run_id = get_value(:product_resource_allocations, :production_run_id, id: product_resource_allocation_id)
      query = <<~SQL
        SELECT fn_packing_specification_code(packing_specification_items.id) AS code, packing_specification_items.id
        FROM packing_specification_items
        JOIN product_setups ON product_setups.id = packing_specification_items.product_setup_id
        WHERE product_setup_template_id = (SELECT product_setup_template_id
                                           FROM production_runs
                                           WHERE id = ?)
        ORDER BY 1
      SQL
      DB[query, run_id].select_map(%i[code id])
    end

    def allocation_for_button_code(system_resource_code) # rubocop:disable Metrics/AbcSize
      line_res = ResourceRepo.new.plant_resource_parent_of_system_resource(Crossbeams::Config::ResourceDefinitions::LINE, system_resource_code)
      raise Crossbeams::InfoError, "Button #{params[:device]} is not part of a LINE" unless line_res.success

      run_id = labeling_run_for_line(line_res.instance)
      raise Crossbeams::InfoError, "There is no active production run for #{params[:device]}" if run_id.nil?

      plant_resource_id = DB[:plant_resources].where(system_resource_id: DB[:system_resources].where(system_resource_code: system_resource_code).get(:id)).get(:id)
      DB[:product_resource_allocations]
        .where(production_run_id: run_id, plant_resource_id: plant_resource_id)
        .first
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
        "parent"."plant_resource_code" AS alias,
        REPLACE("btns"."system_resource_code", "sysres"."system_resource_code" || '-', '') AS button,
        "a"."product_setup_id", "a"."label_template_id",
        "commodities"."code" AS commodity_code,
        "marketing_varieties"."marketing_variety_code",
        "standard_pack_codes"."standard_pack_code",
        "basic_pack_codes"."basic_pack_code",
        "grades"."grade_code",
        "std_fruit_size_counts"."size_count_value",
        "fruit_actual_counts_for_packs"."actual_count_for_pack",
        "fruit_size_references"."size_reference",
        "marks"."mark_code",
        "target_market_groups"."target_market_group_name",
        "organizations"."short_description" AS org_code,
        "product_setups".product_chars,
        CASE WHEN "commodities"."code" = 'SC' THEN
           "fruit_size_references"."size_reference"::text
         ELSE
          "fruit_actual_counts_for_packs"."actual_count_for_pack"::text
         END AS size_ref_or_count,
         "p"."id"
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
        LEFT JOIN "grades" ON "grades"."id" = "product_setups"."grade_id"

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
        SELECT "sysres"."system_resource_code" AS module,
        "p"."plant_resource_code" AS alias
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
      modules = DB[query, production_run_id].select_map(%i[module alias])
      return {} if modules.empty?

      grp = {}
      modules.each { |mod| grp[mod] = buttons }
      grp
    end

    def refresh_pallet_data(id)
      update_query = []
      AppConst::REFRESH_PALLET_DATA_TABLES.each do |table_name|
        AppConst::REFRESH_PALLET_DATA_COLUMNS.each { |column_name| update_query << update_column_sql(table_name, column_name, id) }
      end
      DB[update_query.join].update
    end

    def update_pallet_sequence_cartons(pallet_sequence_id, attrs)
      ctn_labels = DB[:cartons].where(pallet_sequence_id: pallet_sequence_id).select_map(:carton_label_id)
      DB[:carton_labels].where(id: ctn_labels).update(attrs)
    end

    def update_column_sql(table_name, column_name, production_run_id)
      # <<~SQL
      #   UPDATE #{table_name}
      #   SET #{column_name} = ps.#{column_name}
      #   FROM #{table_name} AS c
      #   JOIN product_resource_allocations prl ON c.product_resource_allocation_id = prl.id
      #   JOIN product_setups ps ON prl.product_setup_id = ps.id
      #     AND ps.#{column_name} IS NOT NULL
      #   WHERE c.production_run_id = #{production_run_id}
      #   AND #{table_name}.id = c.id
      #   AND #{table_name}.#{column_name} IS NULL;
      #
      # SQL

      <<~SQL
        UPDATE #{table_name}
        SET #{column_name} =
            (SELECT product_setups.#{column_name}
             FROM product_resource_allocations
             LEFT JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
             WHERE product_setups.#{column_name} IS NOT NULL
              AND product_resource_allocations.id = #{table_name}.product_resource_allocation_id)
        WHERE #{table_name}.production_run_id = #{production_run_id}
         AND #{table_name}.#{column_name} IS NULL;

      SQL
    end

    def find_packing_spec_item_setup_id(packing_specification_item_id)
      DB[:packing_specification_items]
        .where(id: packing_specification_item_id)
        .get(:product_setup_id)
    end

    def production_run_status(id)
      DB.get(Sequel.function(:fn_current_status, 'production_runs', id))
    end

    def validate_run_bin_tipping_criteria_and_control_data(id)
      run = find_production_run(id)
      run.legacy_bintip_criteria.to_h.select { |_, v| v == 't' }.each_key do |column|
        raise Crossbeams::FrameworkError, "Column #{column} is not used for bintip criteria checking." unless AppConst::BINTIP_COLS.keys.include?(column)
        next if %w[farm_code rmt_variety_code commodity_code].include?(column)

        # raise Crossbeams::InfoError, " Bintip criteria requires a value for run.#{column}" if run[AppConst::BINTIP_COLS[column]].nil_or_empty?
        return " Bintip criteria requires a value for run.#{column}" if run[AppConst::BINTIP_COLS[column]].nil_or_empty?
      end
      nil
    end
  end
end
