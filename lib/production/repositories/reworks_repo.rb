# frozen_string_literal: true

module ProductionApp
  class ReworksRepo < BaseRepo # rubocop:disable ClassLength
    build_for_select :reworks_runs,
                     label: :user,
                     value: :id,
                     no_active_check: true,
                     order_by: :user

    build_for_select :reworks_run_types,
                     label: :run_type,
                     value: :id,
                     order_by: :run_type

    build_inactive_select :reworks_run_types,
                          label: :run_type,
                          value: :id,
                          order_by: :run_type

    crud_calls_for :reworks_runs, name: :reworks_run, wrapper: ReworksRun

    def find_reworks_run(id)
      hash = DB["SELECT reworks_runs.id, reworks_runs.reworks_run_type_id, reworks_run_types.run_type AS reworks_run_type,
                 reworks_runs.scrap_reason_id, scrap_reasons.scrap_reason, reworks_runs.remarks,
                 COALESCE(reworks_runs.changes_made, null) AS changes_made,
                 COALESCE(reworks_runs.changes_made ->> 'reworks_action', '') AS reworks_action, reworks_runs.user,
                 array_to_string(COALESCE(reworks_runs.pallets_scrapped, reworks_runs.pallets_unscrapped, reworks_runs.pallets_selected), '\n') AS pallets_selected,
                 array_to_string(reworks_runs.pallets_affected, '\n') AS pallets_affected,
                 COALESCE(reworks_runs.changes_made -> 'pallets' ->> 'pallet_number', '') AS pallet_number,
                 COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' ->> 'pallet_id', '')  AS pallet_id,
                 COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' ->> 'pallet_sequence_number', '')  AS pallet_sequence_number,
                 COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' -> 'changes' -> 'before', null) AS before_state,
                 COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' -> 'changes' -> 'after', null) AS after_state,
                 reworks_runs.created_at, reworks_runs.updated_at
                 FROM reworks_runs JOIN reworks_run_types ON reworks_run_types.id = reworks_runs.reworks_run_type_id
                 LEFT JOIN scrap_reasons ON scrap_reasons.id = reworks_runs.scrap_reason_id
                 WHERE reworks_runs.id = ?", id].first
      return nil if hash.nil?

      ReworksRunFlat.new(hash)
    end

    def find_reworks_run_type(id)
      find_hash(:reworks_run_types, id)[:run_type]
    end

    def find_reworks_run_type_from_run_type(run_type)
      DB[:reworks_run_types].where(run_type: run_type).get(:id)
    end

    def pallet_numbers_exists?(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers).select_map(:pallet_number)
    end

    def scrapped_pallets?(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers, scrapped: true).select_map(:pallet_number)
    end

    def selected_pallet_numbers(sequence_ids)
      DB[:pallets].where(id: DB[:pallet_sequences].where(id: sequence_ids).select(:pallet_id)).map { |p| p[:pallet_number] }
    end

    def selected_scrapped_pallet_numbers(sequence_ids)
      DB[:pallets].where(id: DB[:pallet_sequences].where(id: sequence_ids).select(:scrapped_from_pallet_id)).map { |p| p[:pallet_number] }
    end

    def find_pallet_ids_from_pallet_number(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers).select_map(:id)
    end

    def find_sequence_ids_from_pallet_number(pallet_numbers)
      DB["SELECT id FROM pallet_sequences WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}') AND pallet_id IS NOT NULL"].map { |r| r[:id] } unless pallet_numbers.nil_or_empty?
    end

    def affected_pallet_numbers(sequence_ids, attrs)
      DB[:pallet_sequences].where(id: sequence_ids).where(attrs).map { |p| p[:pallet_number] }
    end

    def scrapping_reworks_run(pallet_numbers, attrs, reworks_run_booleans)
      DB[:pallets].where(pallet_number: pallet_numbers).update(attrs)
      upd = "UPDATE pallet_sequences SET scrapped_from_pallet_id = pallet_id, pallet_id = null, scrapped_at = '#{Time.now}', exit_ref = '#{AppConst::PALLET_EXIT_REF_SCRAPPED}' WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}');" if reworks_run_booleans[:scrap_pallets]
      upd = "UPDATE pallet_sequences SET scrapped_from_pallet_id = null, pallet_id = scrapped_from_pallet_id, scrapped_at = null, exit_ref = null WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}');" if reworks_run_booleans[:unscrap_pallets]
      DB[upd].update
    end

    def existing_record_reworks_run_update(pallet_numbers, pallet_sequence_ids, pallet_sequence_attrs)
      upd = "UPDATE pallets SET pallet_format_id = pallet_sequences.pallet_format_id FROM pallet_sequences
             WHERE pallets.id = pallet_sequences.pallet_id AND pallets.pallet_number IN ('#{pallet_numbers.join('\',\'')}');"
      DB[upd].update
      DB[:pallet_sequences].where(id: pallet_sequence_ids).update(pallet_sequence_attrs)
    end

    def repacking_reworks_run(pallet_numbers)
      pallet_number_ids = pallet_number_ids(pallet_numbers)
      return if pallet_number_ids.empty?

      pallet_number_ids.each do |pallet_id|
        clone_pallet(pallet_id)
      end
    end

    def pallet_number_ids(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers).select_map(:id)
    end

    def clone_pallet(id)  # rubocop:disable Metrics/AbcSize
      sequence_ids = pallet_sequence_ids(id)
      return if sequence_ids.empty?

      pallet_rejected_fields = %i[id pallet_number build_status]
      ps_rejected_fields = %i[id pallet_id pallet_number pallet_sequence_number]

      pallet = pallet(id)
      new_pallet_id = DB[:pallets].insert(pallet.reject { |k, _| pallet_rejected_fields.include?(k) })

      sequence_ids.each do |sequence_id|
        attrs = find_hash(:pallet_sequences, sequence_id).reject { |k, _| ps_rejected_fields.include?(k) }
        DB[:pallet_sequences].insert(attrs.to_h.merge(pallet_sequence_pallet_params(new_pallet_id)).to_h)
      end
    end

    def clone_pallet_sequence(id)
      ps_rejected_fields = %i[id pallet_sequence_number]
      attrs = find_hash(:pallet_sequences, id).reject { |k, _| ps_rejected_fields.include?(k) }
      new_id = DB[:pallet_sequences].insert(attrs)
      new_id
    end

    def remove_pallet_sequence(id)
      upd = "UPDATE pallet_sequences
             SET removed_from_pallet = true, removed_from_pallet_at = '#{Time.now}', pallet_id = null,
             removed_from_pallet_id = pallet_id, carton_quantity = 0, exit_ref = '#{AppConst::PALLET_EXIT_REF_REMOVED}'
             WHERE id = #{id};"
      DB[upd].update
    end

    def pallet_sequence_ids(pallet_id)
      DB[:pallet_sequences].where(pallet_id: pallet_id).select_map(:id)
    end

    def pallet(id)
      find_hash(:pallets, id)
    end

    def pallet_sequence_pallet_params(new_pallet_id)
      pallet = pallet(new_pallet_id)
      {
        pallet_id: pallet[:pallet_id],
        pallet_number: pallet[:pallet_number]
      }
    end

    def reworks_run_pallet_data(pallet_number)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE pallet_number = ?", pallet_number].first
    end

    def reworks_run_pallet_seq_data(id)
      DB["SELECT *
          FROM vw_pallet_sequence_flat
          WHERE id = ?", id].first
    end

    def sequence_setup_attrs(id)
      DB["SELECT marketing_variety_id, customer_variety_variety_id, std_fruit_size_count_id, basic_pack_code_id,
          standard_pack_code_id, fruit_actual_counts_for_pack_id, fruit_size_reference_id, marketing_org_party_role_id,
          packed_tm_group_id, mark_id, inventory_code_id, pallet_format_id, cartons_per_pallet_id, pm_bom_id, client_size_reference,
          client_product_code, treatment_ids, marketing_order_number, sell_by_code, grade_id, product_chars
          FROM pallet_sequences
          WHERE id = ?", id].first
    end

    def sequence_setup_data(id)
      DB["SELECT marketing_variety, customer_variety, std_size, basic_pack, std_pack, actual_count, size_ref, marketing_org,
          packed_tm_group, mark, inventory_code, pallet_base, stack_type, cpp, bom, client_size_ref,
          client_product_code, treatments, order_number, sell_by_code, grade, product_chars
          FROM vw_pallet_sequence_flat
          WHERE id = ?", id].first
    end

    def sequence_edit_data(attrs)  # rubocop:disable Metrics/AbcSize
      pallet_format = MasterfilesApp::PackagingRepo.new.find_pallet_format(attrs[:pallet_format_id])
      { marketing_variety: get(:marketing_varieties, attrs[:marketing_variety_id], :marketing_variety_code),
        customer_variety: customer_variety_variety(attrs[:customer_variety_variety_id]),
        std_size: get(:std_fruit_size_counts, attrs[:std_fruit_size_count_id], :size_count_value),
        basic_pack: get(:basic_pack_codes, attrs[:basic_pack_code_id], :basic_pack_code),
        std_pack: get(:standard_pack_codes, attrs[:standard_pack_code_id], :standard_pack_code),
        actual_count: get(:fruit_actual_counts_for_packs, attrs[:fruit_actual_counts_for_pack_id], :actual_count_for_pack),
        size_ref: get(:fruit_size_references, attrs[:fruit_size_reference_id], :size_reference),
        marketing_org: DB['SELECT fn_party_role_name(?) AS marketing_org FROM party_roles WHERE party_roles.id = ?', attrs[:marketing_org_party_role_id], attrs[:marketing_org_party_role_id]].first[:marketing_org],
        packed_tm_group: get(:target_market_groups, attrs[:packed_tm_group_id], :target_market_group_name),
        mark: get(:marks, attrs[:mark_id], :mark_code),
        inventory_code: get(:inventory_codes, attrs[:inventory_code_id], :inventory_code),
        pallet_base: get(:pallet_bases, pallet_format[:pallet_base_id], :pallet_base_code),
        stack_type: get(:pallet_stack_types, pallet_format[:pallet_stack_type_id], :stack_type_code),
        cpp: get(:cartons_per_pallet, attrs[:cartons_per_pallet_id], :cartons_per_pallet),
        bom: get(:pm_boms, attrs[:pm_bom_id], :bom_code),
        client_size_ref: attrs[:client_size_reference],
        client_product_code: attrs[:client_product_code],
        treatments: treatments(attrs[:treatment_ids]),
        order_number: attrs[:marketing_order_number],
        sell_by_code: attrs[:sell_by_code],
        grade: get(:grades, attrs[:grade_id], :grade_code),
        product_chars: attrs[:product_chars] }
    end

    def customer_variety_variety(customer_variety_variety_id)
      DB[:marketing_varieties]
        .join(:customer_variety_varieties, marketing_variety_id: :id)
        .join(:customer_varieties, id: :customer_variety_id)
        .where(Sequel[:customer_variety_varieties][:id] => customer_variety_variety_id)
        .get(:marketing_variety_code)
    end

    def treatments(treatment_ids)
      query = <<~SQL
        SELECT array_agg(treatment_code) AS treatments
        FROM treatments
        WHERE treatments.id IN (#{treatment_ids.join(',')})
      SQL
      DB[query].order(:treatment_code).get(:treatments)
    end

    # def find_product_setup_id(sequence_id)
    #   DB[:pallet_sequences]
    #     .join(:product_resource_allocations, id: :product_resource_allocation_id)
    #     .where(Sequel[:pallet_sequences][:id] => sequence_id)
    #     .get(:product_setup_id)
    # end

    def find_production_run_id(sequence_id)
      DB[:pallet_sequences].where(id: sequence_id).get(:production_run_id)
    end

    def reworks_run_pallet_quantities(pallet_number)
      query = <<~SQL
        SELECT pallet_sequence_number, carton_quantity
        FROM vw_pallet_sequence_flat
        WHERE pallet_number = '#{pallet_number}'
        ORDER BY pallet_sequence_number
      SQL
      DB[query].order(:puc_code).select_map(%i[pallet_sequence_number carton_quantity])
    end

    def edit_carton_quantities(id, carton_quantity)
      update(:pallet_sequences, id, carton_quantity: carton_quantity)
    end

    def pallet_seq_carton_quantity(pallet_id)
      DB[:pallet_sequences].where(pallet_id: pallet_id).select_map(:carton_quantity)
    end

    def for_select_production_runs(production_run_id)
      query = <<~SQL
        SELECT fn_production_run_code(id) AS production_run_code, id
        FROM production_runs
        WHERE id NOT IN (#{production_run_id})
        AND cultivar_group_id = (SELECT cultivar_group_id FROM production_runs WHERE id = #{production_run_id})
        ORDER BY id DESC
        LIMIT 500
      SQL
      DB[query].all.map { |r| [r[:production_run_code], r[:id]] }
    end

    def production_run_details(id)
      query = <<~SQL
        SELECT production_runs.id, packhouse.plant_resource_code AS packhouse_code, line.plant_resource_code AS line_code,
               farms.farm_code, pucs.puc_code, orchards.orchard_code, cultivar_groups.cultivar_group_code, cultivars.cultivar_name
        FROM production_runs
        LEFT JOIN plant_resources packhouse ON packhouse.id = production_runs.packhouse_resource_id
        LEFT JOIN plant_resources line ON line.id = production_runs.production_line_id
        LEFT JOIN farms ON farms.id = production_runs.farm_id
        LEFT JOIN pucs ON pucs.id = production_runs.puc_id
        LEFT JOIN orchards ON orchards.id = production_runs.orchard_id
        LEFT JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
        LEFT JOIN cultivars ON cultivars.id = production_runs.cultivar_id
        WHERE production_runs.id = #{id}
      SQL
      DB[query].all unless id.nil?
    end

    def update_pallet_sequence(sequence_id, attrs)
      DB[:pallet_sequences].where(id: sequence_id).update(attrs)
    end

    def oldest_sequence_standard_pack_code(pallet_number)
      query = <<~SQL
        SELECT standard_pack_code_id
        FROM pallet_sequences
        WHERE pallet_number = '#{pallet_number}'
          AND pallet_sequence_number = ( SELECT MIN(pallet_sequence_number)
                                         FROM pallet_sequences
                                         WHERE pallet_number = '#{pallet_number}' AND pallet_id IS NOT NULL)
      SQL
      DB[query].get(:standard_pack_code_id) unless pallet_number.nil_or_empty?
    end

    def update_pallet_gross_weight(pallet_id, attrs)
      DB[:pallet_sequences].where(pallet_id: pallet_id).update(standard_pack_code_id: attrs[:standard_pack_code_id])
      DB[:pallets].where(id: pallet_id).update(gross_weight: attrs[:gross_weight])
    end

    def update_pallet(pallet_id, attrs)
      DB[:pallets].where(id: pallet_id).update(attrs)
    end

    def unscrapped_sequences_count(pallet_id)
      query = <<~SQL
        SELECT count(id)
        FROM pallet_sequences
        WHERE pallet_id = #{pallet_id}
      SQL
      DB[query].single_value
    end

    def for_select_standard_pack_codes
      DB[:standard_pack_codes]
        .where(Sequel.lit('material_mass').> 0) # rubocop:disable Style/NumericPredicate
        .order(:standard_pack_code)
        .distinct
        .select_map(%i[standard_pack_code id])
    end

    def find_pallet_sequence_setup_data(sequence_id)
      hash = DB["SELECT ps.id, ps.pallet_number, ps.pallet_sequence_number, ps.marketing_variety_id, ps.customer_variety_variety_id,
                 ps.std_fruit_size_count_id, ps.basic_pack_code_id, ps.standard_pack_code_id, ps.fruit_actual_counts_for_pack_id, ps.fruit_size_reference_id,
                 ps.marketing_org_party_role_id, ps.packed_tm_group_id, ps.mark_id, ps.inventory_code_id, ps.pallet_format_id, ps.cartons_per_pallet_id,
                 ps.pm_bom_id, ps.client_size_reference, ps.client_product_code, ps.treatment_ids, ps.marketing_order_number, ps.sell_by_code, --p.pallet_label_name,
                 cultivar_groups.commodity_id, ps.grade_id, ps.product_chars, pallet_formats.pallet_base_id, pallet_formats.pallet_stack_type_id,
                 pm_subtypes.pm_type_id, pm_products.pm_subtype_id, pm_boms.description, pm_boms.erp_bom_code
                 FROM pallet_sequences ps
                 JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
                 JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
                 LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
                 LEFT JOIN pm_boms_products ON pm_boms_products.pm_bom_id = ps.pm_bom_id
                 LEFT JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
                 LEFT JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
                 WHERE ps.id = ?", sequence_id].first

      return nil if hash.nil?

      OpenStruct.new(hash)
    end

    def for_select_template_commodity_marketing_varieties(commodity_id)  # rubocop:disable Metrics/AbcSize
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .join(:cultivar_groups, id: :cultivar_group_id)
        .where(Sequel[:cultivars][:commodity_id] => commodity_id)
        .distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:marketing_varieties][:id],
          Sequel[:marketing_varieties][:marketing_variety_code]
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def for_selected_second_pm_products(pm_type, fruit_sticker_pm_product_id)
      DB["SELECT p.id, p.product_code
          FROM pm_products p
          JOIN pm_subtypes s on s.id = p.pm_subtype_id
          JOIN pm_types t on t.id = s.pm_type_id
          WHERE t.pm_type_code = '#{pm_type}' AND p.id != #{fruit_sticker_pm_product_id}"].map { |r| [r[:product_code], r[:id]] }
    end
  end
end
