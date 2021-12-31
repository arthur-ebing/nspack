# frozen_string_literal: true

module ProductionApp
  class GrowerGradingRepo < BaseRepo
    build_for_select :grower_grading_rules,
                     label: :rule_name,
                     value: :id,
                     order_by: :rule_name
    build_inactive_select :grower_grading_rules,
                          label: :rule_name,
                          value: :id,
                          order_by: :rule_name

    build_for_select :grower_grading_pools,
                     label: :pool_name,
                     value: :id,
                     order_by: :pool_name
    build_inactive_select :grower_grading_pools,
                          label: :pool_name,
                          value: :id,
                          order_by: :pool_name

    crud_calls_for :grower_grading_rules, name: :grower_grading_rule, wrapper: GrowerGradingRule
    crud_calls_for :grower_grading_rule_items, name: :grower_grading_rule_item, wrapper: GrowerGradingRuleItem
    crud_calls_for :grower_grading_pools, name: :grower_grading_pool, wrapper: GrowerGradingPool
    crud_calls_for :grower_grading_cartons, name: :grower_grading_carton, wrapper: GrowerGradingCarton
    crud_calls_for :grower_grading_rebins, name: :grower_grading_rebin, wrapper: GrowerGradingRebin

    def find_grower_grading_rule(id)
      find_with_association(:grower_grading_rules,
                            id,
                            parent_tables: [{ parent_table: :plant_resources,
                                              columns: [:plant_resource_code],
                                              foreign_key: :packhouse_resource_id,
                                              flatten_columns: { plant_resource_code: :packhouse_resource_code } },
                                            { parent_table: :plant_resources,
                                              columns: [:plant_resource_code],
                                              foreign_key: :line_resource_id,
                                              flatten_columns: { plant_resource_code: :line_resource_code } },
                                            { parent_table: :cultivar_groups,
                                              columns: [:cultivar_group_code],
                                              flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                            { parent_table: :cultivars,
                                              columns: [:cultivar_name],
                                              flatten_columns: { cultivar_name: :cultivar_name } },
                                            { parent_table: :seasons,
                                              columns: [:season_code],
                                              flatten_columns: { season_code: :season_code } }],
                            wrapper: GrowerGradingRuleFlat)
    end

    def find_grower_grading_rule_item(id)
      find_with_association(:grower_grading_rule_items,
                            id,
                            parent_tables: [{ parent_table: :grower_grading_rules,
                                              columns: [:rule_name],
                                              flatten_columns: { rule_name: :grading_rule } },
                                            { parent_table: :commodities,
                                              columns: [:code],
                                              flatten_columns: { code: :commodity_code } },
                                            { parent_table: :marketing_varieties,
                                              columns: [:marketing_variety_code],
                                              flatten_columns: { marketing_variety_code: :marketing_variety_code } },
                                            { parent_table: :grades,
                                              columns: [:grade_code],
                                              flatten_columns: { grade_code: :grade_code } },
                                            { parent_table: :inspection_types,
                                              columns: [:inspection_type_code],
                                              flatten_columns: { inspection_type_code: :inspection_type_code } },
                                            { parent_table: :rmt_classes,
                                              columns: [:rmt_class_code],
                                              flatten_columns: { rmt_class_code: :rmt_class_code } },
                                            { parent_table: :rmt_sizes,
                                              columns: [:size_code],
                                              flatten_columns: { size_code: :rmt_size_code } },
                                            { parent_table: :fruit_actual_counts_for_packs,
                                              columns: [:actual_count_for_pack],
                                              flatten_columns: { actual_count_for_pack: :actual_count } },
                                            { parent_table: :std_fruit_size_counts,
                                              columns: [:size_count_value],
                                              flatten_columns: { size_count_value: :size_count } },
                                            { parent_table: :fruit_size_references,
                                              columns: [:size_reference],
                                              flatten_columns: { size_reference: :size_reference } }],
                            lookup_functions: [{ function: :fn_grading_rule_item_code,
                                                 args: [:id],
                                                 col_name: :rule_item_code }],
                            wrapper: GrowerGradingRuleItemFlat)
    end

    def find_grower_grading_pool(id)
      find_with_association(:grower_grading_pools,
                            id,
                            parent_tables: [{ parent_table: :commodities,
                                              columns: [:code],
                                              flatten_columns: { code: :commodity_code } },
                                            { parent_table: :cultivar_groups,
                                              columns: [:cultivar_group_code],
                                              flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                            { parent_table: :cultivars,
                                              columns: [:cultivar_name],
                                              flatten_columns: { cultivar_name: :cultivar_name } },
                                            { parent_table: :seasons,
                                              columns: [:season_code],
                                              flatten_columns: { season_code: :season_code } },
                                            { parent_table: :farms,
                                              columns: [:farm_code],
                                              flatten_columns: { farm_code: :farm_code } },
                                            { parent_table: :inspection_types,
                                              columns: [:inspection_type_code],
                                              flatten_columns: { inspection_type_code: :inspection_type_code } }],
                            lookup_functions: [{ function: :fn_production_run_code,
                                                 args: [:production_run_id],
                                                 col_name: :production_run_code }],
                            wrapper: GrowerGradingPoolFlat)
    end

    def find_grower_grading_carton(id)
      find_with_association(:grower_grading_cartons,
                            id,
                            parent_tables: [{ parent_table: :grower_grading_pools,
                                              columns: [:pool_name],
                                              flatten_columns: { pool_name: :pool_name } },
                                            { parent_table: :pm_boms,
                                              columns: [:bom_code],
                                              flatten_columns: { bom_code: :bom_code } },
                                            { parent_table: :marketing_varieties,
                                              columns: [:marketing_variety_code],
                                              flatten_columns: { marketing_variety_code: :marketing_variety_code } },
                                            { parent_table: :grades,
                                              columns: [:grade_code],
                                              flatten_columns: { grade_code: :grade_code } },
                                            { parent_table: :target_market_groups,
                                              columns: [:target_market_group_name],
                                              flatten_columns: { target_market_group_name: :packed_tm_group } },
                                            { parent_table: :target_markets,
                                              columns: [:target_market_name],
                                              flatten_columns: { target_market_name: :target_market } },
                                            { parent_table: :inventory_codes,
                                              columns: [:inventory_code],
                                              flatten_columns: { inventory_code: :inventory_code } },
                                            { parent_table: :rmt_classes,
                                              columns: [:rmt_class_code],
                                              flatten_columns: { rmt_class_code: :rmt_class_code } },
                                            { parent_table: :fruit_actual_counts_for_packs,
                                              columns: [:actual_count_for_pack],
                                              flatten_columns: { actual_count_for_pack: :actual_count } },
                                            { parent_table: :std_fruit_size_counts,
                                              columns: [:size_count_value],
                                              flatten_columns: { size_count_value: :size_count } },
                                            { parent_table: :fruit_size_references,
                                              columns: [:size_reference],
                                              flatten_columns: { size_reference: :size_reference } }],
                            lookup_functions: [{ function: :fn_party_role_name,
                                                 args: [:marketing_org_party_role_id],
                                                 col_name: :marketing_org },
                                               { function: :fn_grading_carton_code,
                                                 args: [:id],
                                                 col_name: :grading_carton_code }],
                            wrapper: GrowerGradingCartonFlat)
    end

    def find_grower_grading_rebin(id)
      find_with_association(:grower_grading_rebins,
                            id,
                            parent_tables: [{ parent_table: :grower_grading_pools,
                                              columns: [:pool_name],
                                              flatten_columns: { pool_name: :pool_name } },
                                            { parent_table: :rmt_classes,
                                              columns: [:rmt_class_code],
                                              flatten_columns: { rmt_class_code: :rmt_class_code } },
                                            { parent_table: :rmt_sizes,
                                              columns: [:size_code],
                                              flatten_columns: { size_code: :rmt_size_code } }],
                            lookup_functions: [{ function: :fn_grading_rebin_code,
                                                 args: [:id],
                                                 col_name: :grading_rebin_code }],
                            wrapper: GrowerGradingRebinFlat)
    end

    def activate_grower_grading_rule(id)
      activate(:grower_grading_rules, id)
    end

    def deactivate_grower_grading_rule(id)
      deactivate(:grower_grading_rules, id)
    end

    def activate_grower_grading_rule_item(id)
      activate(:grower_grading_rule_items, id)
    end

    def deactivate_grower_grading_rule_item(id)
      deactivate(:grower_grading_rule_items, id)
    end

    def delete_grower_grading_rule(id)
      DB[:grower_grading_rule_items].where(grower_grading_rule_id: id).delete
      DB[:grower_grading_rules].where(id: id).delete
      { success: true }
    end

    def delete_grower_grading_pool(id)
      DB[:grower_grading_cartons].where(grower_grading_pool_id: id).delete
      DB[:grower_grading_rebins].where(grower_grading_pool_id: id).delete
      DB[:grower_grading_pools].where(id: id).delete
      { success: true }
    end

    def clone_grower_grading_rule_items(id, args)
      rule_item_ids = grower_grading_rule_item_ids(id)
      return if rule_item_ids.empty?

      rule_item_ids.each do |rule_item_id|
        attrs = find_hash(:grower_grading_rule_items, rule_item_id).reject { |k, _| %i[id grower_grading_rule_id].include?(k) }
        attrs[:active] = false
        create(:grower_grading_rule_items, attrs.merge(args))
      end
    end

    def grower_grading_rule_item_ids(grower_grading_rule_id)
      DB[:grower_grading_rule_items]
        .where(grower_grading_rule_id: grower_grading_rule_id)
        .select_map(:id)
    end

    def clone_grower_grading_rule_item(id)
      attrs = find_hash(:grower_grading_rule_items, id).reject { |k, _| k == :id }
      create(:grower_grading_rule_items, attrs)
    end

    def for_select_grading_rule_commodities(cultivar_group_id, cultivar_id = nil) # rubocop:disable Metrics/AbcSize
      ds = DB[:grower_grading_rules]
           .join(:cultivar_groups, id: :cultivar_group_id)
           .join(:commodities, id: Sequel[:cultivar_groups][:commodity_id])
           .left_join(:cultivars, id: Sequel[:grower_grading_rules][:cultivar_id])
           .where(Sequel[:grower_grading_rules][:cultivar_group_id] => cultivar_group_id)
      ds = ds.where(Sequel[:grower_grading_rules][:cultivar_id] => cultivar_id) unless cultivar_id.nil_or_empty?
      ds.distinct(Sequel[:commodities][:code])
        .select(
          Sequel[:commodities][:id],
          Sequel[:commodities][:code]
        )
        .order(:code)
        .map { |r| [r[:code], r[:id]] }
    end

    def for_select_cultivar_group_marketing_varieties(cultivar_group_id, cultivar_id = nil) # rubocop:disable Metrics/AbcSize
      ds = DB[:marketing_varieties]
           .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
           .join(:cultivars, id: :cultivar_id)
           .where(cultivar_group_id: cultivar_group_id)
      ds = ds.where(Sequel[:cultivars][:id] => cultivar_id) unless cultivar_id.nil_or_empty?
      ds.distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:marketing_varieties][:id],
          Sequel[:marketing_varieties][:marketing_variety_code]
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def grower_grading_rule_changes(grower_grading_rule_id)
      rebin_rule = get(:grower_grading_rules, :rebin_rule, grower_grading_rule_id)
      rebin_rule ? AppConst::CR_PROD.grower_grading_json_fields[:rebin_changes] : AppConst::CR_PROD.grower_grading_json_fields[:carton_changes]
    end

    def look_for_existing_rule_item_id(res)
      args = res.to_h.reject { |k, _| %i[id created_by updated_by legacy_data changes].include?(k) }
      get_id(:grower_grading_rule_items, args)
    end

    def no_rule_item_changes?(grower_grading_rule_item_id, res) # rubocop:disable Metrics/AbcSize
      args = res.to_h
      legacy_data = get(:grower_grading_rule_items, :legacy_data, grower_grading_rule_item_id)
      changes = get(:grower_grading_rule_items, :changes, grower_grading_rule_item_id)
      legacy_data_changes = args[:legacy_data].reject { |k, v|  legacy_data.key?(k.to_s) && legacy_data[k.to_s] == v }
      rule_item_changes = args[:changes].reject { |k, v|  changes.key?(k.to_s) && changes[k.to_s] == v }

      legacy_data_changes.empty? && rule_item_changes.empty?
    end

    def grading_pool_exists?(production_run_id)
      exists?(:grower_grading_pools, production_run_id: production_run_id)
    end

    def rule_exists?(grower_grading_rule_id)
      exists?(:grower_grading_rules, id: grower_grading_rule_id, active: true)
    end

    def rule_item_exists?(grower_grading_rule_item_id)
      exists?(:grower_grading_rule_items, id: grower_grading_rule_item_id, active: true)
    end

    def production_run_carton_exists?(production_run_id)
      query = <<~SQL
        SELECT EXISTS(
           SELECT cartons.id
           FROM carton_labels
           JOIN cartons ON carton_labels.id = cartons.carton_label_id
           WHERE carton_labels.production_run_id = ? AND cartons.active AND NOT cartons.scrapped
        )
      SQL
      DB[query, production_run_id].single_value
    end

    def production_run_rebin_exists?(production_run_id)
      exists?(:rmt_bins, production_run_rebin_id: production_run_id, active: true, scrapped: false)
    end

    def grower_grading_carton_ids(grower_grading_pool_id)
      DB[:grower_grading_cartons].where(grower_grading_pool_id: grower_grading_pool_id).select_map(:id)
    end

    def grower_grading_rebin_ids(grower_grading_pool_id)
      DB[:grower_grading_rebins].where(grower_grading_pool_id: grower_grading_pool_id).select_map(:id)
    end

    def grower_grading_pool_commodity_id(grower_grading_pool_id)
      DB[:grower_grading_pools]
        .where(id: grower_grading_pool_id)
        .get(:commodity_id)
    end

    def grower_grading_carton_pool_id(grower_grading_carton_id)
      DB[:grower_grading_cartons]
        .where(id: grower_grading_carton_id)
        .get(:grower_grading_pool_id)
    end

    def grading_carton_size_count_id(grower_grading_carton_id, size_count)
      pool_id = grower_grading_carton_pool_id(grower_grading_carton_id)
      get_id(:std_fruit_size_counts, { commodity_id: grower_grading_pool_commodity_id(pool_id), size_count_value: size_count })
    end

    def production_run_grading_pool_details(production_run_id)
      query = <<~SQL
        SELECT production_runs.id AS production_run_id,
               fn_production_run_code(production_runs.id) AS pool_name,
               production_runs.legacy_bintip_criteria->> 'track_indicator_code' AS track_indicator_code,
               production_runs.cultivar_group_id,
               production_runs.cultivar_id,
               production_runs.farm_id,
               production_runs.season_id,
               seasons.commodity_id,
               SUM(rmt_bins.qty_bins) AS bin_quantity,
               SUM(rmt_bins.gross_weight) AS gross_weight,
               SUM(rmt_bins.nett_weight) AS nett_weight
        FROM production_runs
        JOIN seasons on production_runs.season_id = seasons.id
        JOIN rmt_bins on production_runs.id = rmt_bins.production_run_tipped_id
        WHERE production_runs.id = ? AND rmt_bins.active AND NOT rmt_bins.scrapped
        GROUP BY production_runs.id, seasons.commodity_id
      SQL
      DB[query, production_run_id].first || {} unless production_run_id.nil?
    end

    def production_run_grading_carton_details(production_run_id)
      query = <<~SQL
        SELECT carton_labels.production_run_id, carton_labels.pm_bom_id,
               carton_labels.std_fruit_size_count_id, carton_labels.fruit_actual_counts_for_pack_id,
               carton_labels.marketing_org_party_role_id, carton_labels.packed_tm_group_id, carton_labels.target_market_id,
               carton_labels.inventory_code_id, carton_labels.rmt_class_id, carton_labels.grade_id,
               carton_labels.marketing_variety_id, carton_labels.fruit_size_reference_id,
               COUNT(cartons.id) AS carton_quantity,
               COUNT(inspections.id) AS inspected_quantity,
               COUNT(failed_inspections.id) AS failed_quantity,
               SUM(cartons.gross_weight) AS gross_weight,
               SUM(cartons.nett_weight) AS nett_weight
        FROM carton_labels
        JOIN cartons ON cartons.carton_label_id = carton_labels.id
        LEFT JOIN inspections ON inspections.carton_id = cartons.id
        LEFT JOIN inspections failed_inspections ON inspections.carton_id = cartons.id AND NOT failed_inspections.passed
        WHERE carton_labels.production_run_id = ? AND cartons.active AND NOT cartons.scrapped
        GROUP BY carton_labels.production_run_id, carton_labels.pm_bom_id,
                 carton_labels.packed_tm_group_id, carton_labels.target_market_id, carton_labels.inventory_code_id,
                 carton_labels.rmt_class_id, carton_labels.grade_id, carton_labels.marketing_variety_id,
                 carton_labels.std_fruit_size_count_id, carton_labels.fruit_actual_counts_for_pack_id,
                 carton_labels.marketing_org_party_role_id, carton_labels.fruit_size_reference_id
      SQL
      DB[query, production_run_id].all unless production_run_id.nil?
    end

    def production_run_grading_rebin_details(production_run_id)
      query = <<~SQL
        SELECT rmt_bins.production_run_rebin_id AS production_run_id,
               rmt_bins.rmt_class_id,
               rmt_bins.rmt_size_id,
               CASE WHEN rmt_bins.converted_from_pallet_sequence_id is not null THEN true ELSE false END AS pallet_rebin,
               SUM(rmt_bins.qty_bins) AS rebins_quantity,
               SUM(rmt_bins.gross_weight) AS gross_weight,
               SUM(rmt_bins.nett_weight) AS nett_weight
        FROM rmt_bins
        WHERE rmt_bins.production_run_rebin_id = ? AND is_rebin AND active AND NOT scrapped
        GROUP BY rmt_bins.production_run_rebin_id, rmt_bins.rmt_class_id,
		         rmt_bins.rmt_size_id, rmt_bins.converted_from_pallet_sequence_id
      SQL
      DB[query, production_run_id].all unless production_run_id.nil?
    end

    def complete_pool_objects_grading?(grower_grading_pool_id, object_name)
      table_name = "grower_grading_#{object_name}"
      return false unless exists?(table_name.to_sym, grower_grading_pool_id: grower_grading_pool_id)

      !exists?(table_name.to_sym, grower_grading_pool_id: grower_grading_pool_id, changes_made: nil)
    end

    def reopen_pool_objects_grading?(grower_grading_pool_id, object_name)
      table_name = "grower_grading_#{object_name}"
      return false unless exists?(table_name.to_sym, grower_grading_pool_id: grower_grading_pool_id)

      !exists?(table_name.to_sym, grower_grading_pool_id: grower_grading_pool_id, completed: false)
    end

    def match_pools_on_rule_item_attrs(grower_grading_rule_item_id)
      DB[:grower_grading_rules]
        .join(:grower_grading_rule_items, grower_grading_rule_id: :id)
        .where(Sequel[:grower_grading_rule_items][:id] => grower_grading_rule_item_id)
        .distinct
        .select(:season_id,
                :cultivar_group_id,
                :cultivar_id,
                :commodity_id,
                :inspection_type_id,
                Sequel.lit("legacy_data ->> 'track_indicator_code'").as('track_indicator_code'))
        .first
    end

    def find_pools_matching_rule_item_on(args) # rubocop:disable Metrics/AbcSize
      ds = DB[:grower_grading_pools]
           .exclude(completed: true, rule_applied: true)
           .where(active: true, cultivar_group_id: args[:cultivar_group_id])
      ds = ds.where(cultivar_id: args[:cultivar_id]) unless args[:cultivar_id].nil_or_empty?
      ds = ds.where(season_id: args[:season_id]) unless args[:season_id].nil_or_empty?
      ds = ds.where(commodity_id: args[:commodity_id]) unless args[:commodity_id].nil_or_empty?
      ds = ds.where(inspection_type_id: args[:inspection_type_id]) unless args[:inspection_type_id].nil_or_empty?
      ds = ds.where(Sequel.lit("legacy_data ->> 'track_indicator_code'") => args[:track_indicator_code]) unless args[:track_indicator_code].nil_or_empty?
      ds.distinct
        .select_map(:id)
    end
  end
end
