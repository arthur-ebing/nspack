# frozen_string_literal: false

module ProductionApp
  class ReworksRepo < BaseRepo # rubocop:disable Metrics/ClassLength
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

    def find_reworks_run_type(id)
      DB[:reworks_run_types].where(id: id).first
    end

    def find_reworks_run(id)
      query = <<~SQL
        SELECT reworks_runs.id, reworks_runs.reworks_run_type_id, reworks_run_types.run_type AS reworks_run_type,
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
        COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' -> 'changes' -> 'change_descriptions' -> 'before', null) AS before_descriptions_state,
        COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' -> 'changes' -> 'change_descriptions' -> 'after', null) AS after_descriptions_state,
        COALESCE(reworks_runs.changes_made -> 'pallets' -> 'pallet_sequences' -> 'changes', null) AS changes_made_array,
        reworks_runs.allow_cultivar_group_mixing,
        reworks_runs.allow_cultivar_mixing,
        reworks_runs.created_at, reworks_runs.updated_at,
        EXISTS(SELECT id FROM reworks_runs cr WHERE cr.parent_id = reworks_runs.id) AS has_children
        FROM reworks_runs JOIN reworks_run_types ON reworks_run_types.id = reworks_runs.reworks_run_type_id
        LEFT JOIN scrap_reasons ON scrap_reasons.id = reworks_runs.scrap_reason_id
        WHERE reworks_runs.id = #{id}
      SQL
      hash = DB[query].first
      return nil if hash.nil?

      ReworksRunFlat.new(hash)
    end

    def get_reworks_run_type_id(attrs)
      run_type = attrs.gsub('_', ' ').upcase
      DB[:reworks_run_types].where(run_type: run_type).get(:id)
    end

    def pallet_numbers_exists?(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers).select_map(:pallet_number)
    end

    def rmt_bins_exists?(rmt_bins)
      # return rmt_bin_asset_number_exists?(rmt_bins) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      DB[:rmt_bins].where(id: rmt_bins).select_map(:id)
    end

    def production_run_exists?(id)
      DB[:production_runs].where(id: id).select_map(:id)
    end

    def same_cultivar_group?(old_production_run_id, new_production_run_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT id
          FROM production_runs
          WHERE id = #{new_production_run_id}
            AND	cultivar_group_id = (SELECT cultivar_group_id FROM production_runs WHERE id = #{old_production_run_id}))
      SQL
      DB[query].single_value
    end

    def same_commodity?(old_production_run_id, new_production_run_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT production_runs.id
          FROM production_runs
          LEFT JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
          WHERE production_runs.id = #{new_production_run_id}
            AND	cultivar_groups.commodity_id = (SELECT cultivar_groups.commodity_id FROM production_runs
                                                LEFT JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
                                                WHERE production_runs.id = #{old_production_run_id}))
      SQL
      DB[query].single_value
    end

    def rmt_bin_asset_number_exists?(rmt_bins)
      bin_asset_number = DB[:rmt_bins].where(bin_asset_number: rmt_bins).select_map(:bin_asset_number).compact
      return DB[:rmt_bins].where(tipped_asset_number: rmt_bins).select_map(:tipped_asset_number).compact if bin_asset_number.nil_or_empty?

      bin_asset_number
    end

    def scrapped_pallets?(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers, scrapped: true).select_map(:pallet_number)
    end

    def repacked_pallets?(pallet_numbers, where: {})
      DB[:pallets]
        .where(pallet_number: pallet_numbers)
        .where(where)
        .select_map(:pallet_number)
    end

    def shipped_pallets?(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers, shipped: true).select_map(:pallet_number)
    end

    def allocated_pallets?(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers, allocated: true).select_map(:pallet_number)
    end

    def production_run_pallets?(pallet_numbers, production_run_id)
      DB[:pallet_sequences].where(pallet_number: pallet_numbers, production_run_id: production_run_id).select_map(:pallet_number)
    end

    def production_run_bins?(bins, production_run_id)
      DB[:rmt_bins].where(id: bins, production_run_tipped_id: production_run_id).select_map(:id)
    end

    def scrapped_bins?(bin_ids)
      DB[:rmt_bins].where(id: bin_ids, scrapped: true).select_map(:id)
    end

    def tipped_bins?(rmt_bins)
      # return rmt_bin_asset_number_tipped?(rmt_bins) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      DB[:rmt_bins].where(id: rmt_bins, bin_tipped: true).select_map(:id)
    end

    def untipped_bins?(rmt_bins)
      DB[:rmt_bins].where(id: rmt_bins, bin_tipped: false).select_map(:id)
    end

    def rmt_bin_asset_number_tipped?(rmt_bins)
      bin_asset_number = DB[:rmt_bins].where(bin_asset_number: rmt_bins, bin_tipped: true).select_map(:bin_asset_number).compact
      return DB[:rmt_bins].where(tipped_asset_number: rmt_bins, bin_tipped: true).select_map(:tipped_asset_number).compact if bin_asset_number.nil_or_empty?

      bin_asset_number
    end

    def rmt_bin_from_asset_number(asset_number)
      bin_asset_number = DB[:rmt_bins].where(bin_asset_number: asset_number).get(:id)
      return DB[:rmt_bins].where(tipped_asset_number: asset_number).get(:id) if bin_asset_number.nil_or_empty?

      bin_asset_number
    end

    def find_rmt_bin(rmt_bin_id)
      select_values(:rmt_bins, :id, id: rmt_bin_id)
    end

    def get_rmt_bin_asset_number(rmt_bin_id)
      select_values(:rmt_bins, :bin_asset_number, id: rmt_bin_id)
    end

    def selected_pallet_numbers(sequence_ids)
      DB[:pallets].where(id: DB[:pallet_sequences].where(id: sequence_ids).select(:pallet_id)).map { |p| p[:pallet_number] }
    end

    def selected_scrapped_pallet_numbers(sequence_ids)
      DB[:pallets].where(id: DB[:pallet_sequences].where(id: sequence_ids).select(:scrapped_from_pallet_id)).map { |p| p[:pallet_number] }
    end

    def selected_pallet_sequences(sequence_ids)
      select_values(:pallet_sequences, :id, id: sequence_ids)
    end

    def selected_rmt_bins(rmt_bin_ids)
      # return selected_rmt_bin_asset_numbers?(rmt_bin_ids) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

      select_values(:rmt_bins, :id, id: rmt_bin_ids, bin_tipped: false)
    end

    def selected_bins(rmt_bin_ids)
      select_values(:rmt_bins, :id, id: rmt_bin_ids)
    end

    def selected_rmt_bin_asset_numbers?(rmt_bin_ids)
      bin_asset_number = DB[:rmt_bins].where(id: rmt_bin_ids).where(bin_tipped: false).map { |p| p[:bin_asset_number] }.compact
      return DB[:rmt_bins].where(id: rmt_bin_ids).where(bin_tipped: false).map { |p| p[:tipped_asset_number] }.compact if bin_asset_number.nil_or_empty?

      bin_asset_number
    end

    def find_pallet_ids_from_pallet_number(pallet_numbers)
      select_values(:pallets, :id, pallet_number: pallet_numbers)
    end

    def find_sequence_ids_from_pallet_number(pallet_numbers)
      DB["SELECT id FROM pallet_sequences WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}') AND pallet_id IS NOT NULL"].map { |r| r[:id] } unless pallet_numbers.nil_or_empty?
    end

    def affected_pallet_numbers(sequence_ids, attrs)
      DB[:pallet_sequences].where(id: sequence_ids).where(attrs).map { |p| p[:pallet_number] }
    end

    def affected_pallet_sequences(sequence_ids, attrs)
      DB[:pallet_sequences].where(id: sequence_ids).where(attrs).map { |p| p[:id] }
    end

    def scrapping_reworks_run(pallet_numbers, attrs, reworks_run_booleans, user_name)
      pallet_ids = find_pallet_ids_from_pallet_number(pallet_numbers)
      pallet_sequence_ids = find_sequence_ids_from_pallet_number(pallet_numbers)
      status = reworks_run_booleans[:scrap_pallets] ? AppConst::PALLET_SCRAPPED : AppConst::PALLET_UNSCRAPPED
      DB[:pallets].where(pallet_number: pallet_numbers).update(attrs)
      upd = "UPDATE pallet_sequences SET scrapped_from_pallet_id = pallet_id, pallet_id = null, scrapped_at = '#{Time.now}', exit_ref = '#{AppConst::PALLET_EXIT_REF_SCRAPPED}' WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}');" if reworks_run_booleans[:scrap_pallets]
      upd = "UPDATE pallet_sequences SET scrapped_from_pallet_id = null, pallet_id = scrapped_from_pallet_id, scrapped_at = null, exit_ref = null WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}');" if reworks_run_booleans[:unscrap_pallets]
      DB[upd].update
      log_pallet_statuses(pallet_ids, pallet_sequence_ids, status, user_name)
    end

    def log_pallet_statuses(pallet_ids, pallet_sequence_ids, status, user_name)
      log_multiple_statuses(:pallets, pallet_ids, status, user_name: user_name)  unless pallet_ids.nil_or_empty?
      log_multiple_statuses(:pallet_sequences, pallet_sequence_ids, status, user_name: user_name) unless pallet_sequence_ids.nil_or_empty?
    end

    def existing_records_batch_update(pallet_numbers, pallet_sequence_ids, pallet_sequence_attrs)
      DB[:pallet_sequences].where(id: pallet_sequence_ids).update(pallet_sequence_attrs)
      pallet_numbers.each do |pallet_number|
        update_pallets_pallet_format(pallet_number)
      end
    end

    def update_pallets_recalc_nett_weight(pallet_numbers, user_name)
      ds = DB[:pallets].where(pallet_number: pallet_numbers)
      ids = ds.select_map(:id)
      ds.update(re_calculate_nett: true)
      log_multiple_statuses(:pallets, ids, 'NETT_WEIGHT_RECALCULATED', user_name: user_name)
    end

    def update_pallets_pallet_format(pallet_number)
      pallet_format_id = where_hash(:pallet_sequences, id: oldest_sequence_id(pallet_number))[:pallet_format_id]

      upd = "UPDATE pallets SET pallet_format_id = #{pallet_format_id} WHERE pallet_number = '#{pallet_number}';"
      DB[upd].update unless pallet_format_id.nil_or_empty?
    end

    def repacking_reworks_run(pallet_numbers, user_name, _attrs)
      pallet_numbers.each do |pallet_number|
        repack_pallet(pallet_number, user_name)
      end
    end

    def repack_pallet(pallet_id, user_name)
      pallet = pallet(pallet_id)
      sequence_ids = pallet_sequence_ids(pallet_id)
      return failed_response("Pallet number #{pallet[:pallet_number]} is missing sequences") if sequence_ids.empty?

      new_pallet_id = clone_pallet(pallet, sequence_ids, user_name)
      scrapped_pallet_attrs = { scrapped: true, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_REPACKED }
      scrapped_pallet_sequence_attrs = { pallet_id: nil, scrapped_from_pallet_id: pallet_id, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_REPACKED }

      update_pallet(pallet_id, scrapped_pallet_attrs)
      update_pallet_sequence(sequence_ids, scrapped_pallet_sequence_attrs)

      success_response('ok', new_pallet_id: new_pallet_id)
    end

    def pallet_number_ids(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers).select_map(:id)
    end

    def pallet_sequence_ids(pallet_id)
      DB[:pallet_sequences].where(pallet_id: pallet_id).select_map(:id)
    end

    def clone_pallet(pallet, sequence_ids, user_name)
      pallet_rejected_fields = %i[id pallet_number build_status shipped in_stock inspected depot_pallet allocated
                                  partially_palletized reinspected scrapped shipped_at scrapped_at govt_first_inspection_at
                                  govt_reinspection_at stock_created_at gross_weight_measured_at allocated_at intake_created_at
                                  first_cold_storage_at nett_weight gross_weight last_govt_inspection_pallet_id]
      repack_attrs = { repacked: true, palletized: true, repacked_at: Time.now, created_at: Time.now, updated_at: Time.now }
      attrs = pallet.to_h.merge(repack_attrs.to_h).reject { |k, _| pallet_rejected_fields.include?(k) }
      new_pallet_id = create(:pallets, attrs)
      clone_pallet_sequences(pallet[:id], new_pallet_id, sequence_ids, user_name)
      new_pallet_id
    end

    def clone_pallet_sequences(old_pallet_id, pallet_id, sequence_ids, user_name) # rubocop:disable Metrics/AbcSize
      pallet = pallet(pallet_id)
      repack_attrs = { pallet_id: pallet[:id], pallet_number: pallet[:pallet_number], repacked_from_pallet_id: old_pallet_id,
                       repacked_at: Time.now, created_at: Time.now, updated_at: Time.now, created_by: user_name }
      ps_rejected_fields = %i[id pallet_id pallet_number pallet_sequence_number depot_pallet verified verification_passed
                              removed_from_pallet verified_by scrapped_at verification_result verified_at
                              removed_from_pallet_at nett_weight]
      sequence_ids.each do |sequence_id|
        attrs = find_hash(:pallet_sequences, sequence_id).to_h.reject { |k, _| ps_rejected_fields.include?(k) }
        new_sequence_id = create(:pallet_sequences, attrs.merge(repack_attrs.to_h))
        DB[:cartons].where(pallet_sequence_id: sequence_id).update({ pallet_sequence_id: new_sequence_id }) if pallet[:has_individual_cartons]
      end
    end

    def clone_pallet_sequence(args)
      ps_rejected_fields = %i[id pallet_sequence_number]
      attrs = find_hash(:pallet_sequences, args[:pallet_sequence_id]).reject { |k, _| ps_rejected_fields.include?(k) }
      attrs[:cultivar_id] = args[:cultivar_id] if args[:allow_cultivar_mixing]
      create(:pallet_sequences, attrs)
    end

    def remove_pallet_sequence(id)
      upd = "UPDATE pallet_sequences
             SET removed_from_pallet = true, removed_from_pallet_at = '#{Time.now}', pallet_id = null,
             removed_from_pallet_id = pallet_id, carton_quantity = 0, exit_ref = '#{AppConst::PALLET_EXIT_REF_REMOVED}'
             WHERE id = #{id};"
      DB[upd].update
    end

    def scrap_carton(id)
      upd = "UPDATE cartons
             SET scrapped = true, scrapped_at = '#{Time.now}', scrapped_reason = '#{AppConst::REWORKS_ACTION_SCRAP_CARTON}',
                 scrapped_sequence_id = pallet_sequence_id, pallet_sequence_id = null
             WHERE id = #{id};"
      DB[upd].update
    end

    def pallet(id)
      find_hash(:pallets, id)
    end

    # def pallet_sequence_pallet_params(new_pallet_id)
    #   pallet = pallet(new_pallet_id)
    #   {
    #     pallet_id: pallet[:pallet_id],
    #     pallet_number: pallet[:pallet_number]
    #   }
    # end

    def reworks_run_pallet_print_data(pallet_number)
      qry = <<~SQL
        SELECT DISTINCT *
        FROM vw_pallet_label
        WHERE pallet_number = ?
      SQL
      DB[qry, pallet_number].first
    end

    def reworks_run_pallet_data(pallet_number)
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.pallet_number = ?')
      DB[query, pallet_number].first
    end

    def reworks_run_pallet_seq_print_data(id)
      qry = <<~SQL
        SELECT *
        FROM vw_carton_label_pseq
        WHERE id = ?
      SQL
      DB[qry, id].first
    end

    def reworks_run_pallet_seq_data(id)
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.id = ?')
      DB[query, id].first
    end

    def sequence_setup_attrs(id)
      DB["SELECT marketing_variety_id, customer_variety_id, std_fruit_size_count_id, basic_pack_code_id,
          standard_pack_code_id, fruit_actual_counts_for_pack_id, fruit_size_reference_id, marketing_org_party_role_id,
          packed_tm_group_id, target_market_id, mark_id, pm_mark_id, inventory_code_id, pallet_format_id, cartons_per_pallet_id, pm_bom_id, client_size_reference,
          client_product_code, treatment_ids, marketing_order_number, sell_by_code, grade_id, product_chars, pm_type_id, pm_subtype_id,
          rmt_class_id, packing_specification_item_id, tu_labour_product_id, ru_labour_product_id, fruit_sticker_ids, tu_sticker_ids, target_customer_party_role_id
          FROM pallet_sequences
          WHERE id = ?", id].first
    end

    def sequence_setup_data(id)
      data_ar = %i[marketing_variety customer_variety std_size basic_pack std_pack actual_count size_ref marketing_org
                   packed_tm_group target_market mark inventory_code pallet_base stack_type cpp client_size_ref
                   client_product_code treatments order_number sell_by_code grade product_chars
                   tu_labour_product ru_labour_product fruit_stickers tu_stickers target_customer color_percentage]
      data_ar << :rmt_class_code if AppConst::CR_PROD.capture_product_setup_class?
      data_ar.push(:pm_mark, :pm_type, :pm_subtype, :bom) if AppConst::CR_PROD.require_packaging_bom?
      query = MesscadaApp::DatasetPalletSequence.call('WHERE pallet_sequences.id = ?')
      DB[query, id].first.select { |key, _| data_ar.include?(key) }
    end

    def sequence_edit_data(attrs) # rubocop:disable Metrics/AbcSize
      party_repo = MasterfilesApp::PartyRepo.new
      args = { basic_pack_code_id: attrs[:basic_pack_code_id], std_fruit_size_count_id: attrs[:std_fruit_size_count_id] }
      fruit_actual_counts_for_pack_id = get_value(:fruit_actual_counts_for_packs, :id, args)

      pallet_format = MasterfilesApp::PackagingRepo.new.find_pallet_format(attrs[:pallet_format_id])
      data_attrs = { marketing_variety: get(:marketing_varieties, attrs[:marketing_variety_id], :marketing_variety_code),
                     customer_variety: customer_variety(attrs[:customer_variety_id]),
                     std_size: get(:std_fruit_size_counts, attrs[:std_fruit_size_count_id], :size_count_value),
                     basic_pack: get(:basic_pack_codes, attrs[:basic_pack_code_id], :basic_pack_code),
                     std_pack: get(:standard_pack_codes, attrs[:standard_pack_code_id], :standard_pack_code),
                     actual_count: get(:fruit_actual_counts_for_packs, fruit_actual_counts_for_pack_id, :actual_count_for_pack),
                     size_ref: get(:fruit_size_references, attrs[:fruit_size_reference_id], :size_reference),
                     marketing_org: party_repo.fn_party_role_name(attrs[:marketing_org_party_role_id]),
                     packed_tm_group: get(:target_market_groups, attrs[:packed_tm_group_id], :target_market_group_name),
                     target_market: get(:target_markets, attrs[:target_market_id], :target_market_name),
                     mark: get(:marks, attrs[:mark_id], :mark_code),
                     inventory_code: get(:inventory_codes, attrs[:inventory_code_id], :inventory_code),
                     pallet_base: get(:pallet_bases, pallet_format[:pallet_base_id], :pallet_base_code),
                     stack_type: get(:pallet_stack_types, pallet_format[:pallet_stack_type_id], :stack_type_code),
                     cpp: get(:cartons_per_pallet, attrs[:cartons_per_pallet_id], :cartons_per_pallet),
                     client_size_ref: attrs[:client_size_reference],
                     client_product_code: attrs[:client_product_code],
                     treatments: treatments(attrs[:treatment_ids]),
                     order_number: attrs[:marketing_order_number],
                     sell_by_code: attrs[:sell_by_code],
                     grade: get(:grades, attrs[:grade_id], :grade_code),
                     product_chars: attrs[:product_chars],
                     tu_labour_product: get(:pm_products, attrs[:tu_labour_product_id], :product_code),
                     ru_labour_product: get(:pm_products, attrs[:ru_labour_product_id], :product_code),
                     fruit_stickers: sticker_values(attrs[:fruit_sticker_ids]),
                     tu_stickers: sticker_values(attrs[:tu_sticker_ids]),
                     target_customer: party_repo.fn_party_role_name(attrs[:target_customer_party_role_id]),
                     color_percentage: get(:color_percentages, attrs[:color_percentage_id], :color_percentage) }
      data_attrs = data_attrs.merge(rmt_class_code: get(:rmt_classes, attrs[:rmt_class_id], :rmt_class_code)) if AppConst::CR_PROD.capture_product_setup_class?
      data_attrs = data_attrs.merge(packaging_bom_attrs(attrs)) if AppConst::CR_PROD.require_packaging_bom?
      data_attrs
    end

    def packaging_bom_attrs(attrs)
      {
        pm_mark: get(:pm_marks, attrs[:pm_mark_id], :packaging_marks),
        pm_type: get(:pm_types, attrs[:pm_type_id], :pm_type_code),
        pm_subtype: get(:pm_subtypes, attrs[:pm_subtype_id], :subtype_code),
        bom: get(:pm_boms, attrs[:pm_bom_id], :bom_code)
      }
    end

    def customer_variety(customer_variety_id)
      DB[:marketing_varieties]
        .join(:customer_varieties, variety_as_customer_variety_id: :id)
        .where(Sequel[:customer_varieties][:id] => customer_variety_id)
        .get(:marketing_variety_code)
    end

    def treatments(treatment_ids)
      return '' if treatment_ids.nil?

      query = <<~SQL
        SELECT array_agg(treatment_code) AS treatments
        FROM treatments
        WHERE treatments.id IN (#{treatment_ids.join(',')})
      SQL
      DB[query].order(:treatment_code).get(:treatments)
    end

    def sticker_values(ids)
      return '' if ids.nil?

      query = <<~SQL
        SELECT array_agg(product_code) AS product_codes
        FROM pm_products
        WHERE pm_products.id IN (#{ids.join(',')})
      SQL
      DB[query].order(:product_code).get(:product_codes)
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
      DB[:pallet_sequences].where(pallet_number: pallet_number).order(:puc_id, :pallet_sequence_number).select_map(%i[pallet_sequence_number carton_quantity])
      # query = <<~SQL
      #   SELECT pallet_sequence_number, carton_quantity
      #   FROM vw_pallet_sequence_flat
      #   WHERE pallet_number = '#{pallet_number}'
      #   ORDER BY pallet_sequence_number
      # SQL
      # DB[query].order(:puc_code).select_map(%i[pallet_sequence_number carton_quantity])
    end

    def edit_carton_quantities(id, carton_quantity)
      update(:pallet_sequences, id, carton_quantity: carton_quantity)
    end

    def pallet_seq_carton_quantity(pallet_id)
      DB[:pallet_sequences].where(pallet_id: pallet_id).select_map(:carton_quantity)
    end

    def for_select_production_runs(production_run_id, allow_cultivar_group_mixing = false)
      conditions = if AppConst::CR_PROD.can_mix_cultivar_groups? && allow_cultivar_group_mixing
                     " AND cultivar_groups.commodity_id = (SELECT cultivar_groups.commodity_id FROM production_runs
                                                           LEFT JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
                                                           WHERE production_runs.id = #{production_run_id})"
                   else
                     " AND production_runs.cultivar_group_id = (SELECT production_runs.cultivar_group_id FROM production_runs
                                                                WHERE production_runs.id = #{production_run_id})"
                   end

      query = <<~SQL
        SELECT fn_production_run_code(production_runs.id) AS production_run_code, production_runs.id
        FROM production_runs
        LEFT JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
        WHERE production_runs.id NOT IN (#{production_run_id})
        #{conditions}
        ORDER BY id DESC
        LIMIT 500
      SQL
      DB[query].all.map { |r| [r[:production_run_code], r[:id]] }
    end

    def production_run_details(id)
      query = <<~SQL
        SELECT production_runs.id AS production_run_id, packhouse.plant_resource_code AS packhouse_code, line.plant_resource_code AS line_code,
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

    def update_rmt_bin(rmt_bin_id, attrs)
      DB[:rmt_bins].where(id: rmt_bin_id).update(attrs)
    end

    def individual_cartons?(sequence_id)
      DB[:pallets]
        .join(:pallet_sequences, pallet_id: :id)
        .where(Sequel[:pallet_sequences][:id] => sequence_id)
        .get(:has_individual_cartons)
    end

    def update_carton_labels_for_pallet_sequence(sequence_id, attrs)
      carton_ids = pallet_sequence_cartons(sequence_id)
      carton_label_ids = carton_carton_label(carton_ids)
      DB[:carton_labels].where(id: carton_label_ids).update(attrs)
    end

    def pallet_sequence_cartons(sequence_id)
      select_values(:cartons, :id, pallet_sequence_id: sequence_id)
    end

    def carton_carton_label(carton_ids)
      select_values(:cartons, :carton_label_id, id: carton_ids)
    end

    def oldest_sequence_id(pallet_number)
      pallet_sequence_number = oldest_sequence_number(pallet_number)
      DB[:pallet_sequences].where(pallet_number: pallet_number).where(pallet_sequence_number: pallet_sequence_number).get(:id) unless pallet_sequence_number.nil_or_empty?
    end

    def oldest_sequence_number(pallet_number)
      query = <<~SQL
        SELECT MIN(pallet_sequence_number) AS pallet_sequence_number
        FROM pallet_sequences
        WHERE pallet_number = '#{pallet_number}' AND pallet_id IS NOT NULL
      SQL
      DB[query].get(:pallet_sequence_number) unless pallet_number.nil_or_empty?
    end

    def update_pallet_gross_weight(pallet_id, attrs, same_standard_pack)
      DB[:pallet_sequences].where(pallet_id: pallet_id).update(standard_pack_code_id: attrs[:standard_pack_code_id]) unless same_standard_pack
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

    def pallet_sequence_carton_quantity(pallet_sequence_id)
      DB[:pallet_sequences].where(id: pallet_sequence_id).get(:carton_quantity)
    end

    def for_select_standard_packs
      DB[:standard_pack_codes]
        .where(Sequel.lit('material_mass').> 0) # rubocop:disable Style/NumericPredicate
        .order(:standard_pack_code)
        .distinct
        .select_map(%i[standard_pack_code id])
    end

    def find_pallet_sequence_setup_data(sequence_id)
      query = <<~SQL
        SELECT ps.id, ps.pallet_number, ps.pallet_sequence_number, ps.marketing_variety_id, ps.customer_variety_id,
        ps.std_fruit_size_count_id, ps.basic_pack_code_id, ps.standard_pack_code_id, ps.fruit_actual_counts_for_pack_id,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count, ps.fruit_size_reference_id,
        ps.marketing_org_party_role_id, ps.packed_tm_group_id, ps.target_market_id, ps.mark_id, ps.pm_mark_id, ps.inventory_code_id, ps.pallet_format_id, ps.cartons_per_pallet_id,
        ps.pm_bom_id, ps.client_size_reference, ps.client_product_code, ps.treatment_ids, ps.marketing_order_number, ps.sell_by_code,
        cultivar_groups.commodity_id, ps.grade_id, ps.product_chars, pallet_formats.pallet_base_id, pallet_formats.pallet_stack_type_id,
        ps.pm_type_id, ps.pm_subtype_id, pm_boms.description, pm_boms.erp_bom_code, ps.pallet_id, ps.cultivar_group_id, ps.cultivar_id, ps.production_run_id,
        packhouses.plant_resource_code AS packhouse, lines.plant_resource_code AS line, farms.farm_code AS farm,
        pucs.puc_code AS puc, orchards.orchard_code AS orchard, cultivar_groups.cultivar_group_code AS cultivar_group,
        cultivars.cultivar_name AS cultivar, ps.packing_specification_item_id, ps.tu_labour_product_id, ps.ru_labour_product_id,
        ps.fruit_sticker_ids, ps.rmt_class_id, ps.target_customer_party_role_id, ps.color_percentage_id
        FROM pallet_sequences ps
        JOIN cultivar_groups ON cultivar_groups.id = ps.cultivar_group_id
        LEFT JOIN cultivars ON cultivars.id = ps.cultivar_id
        JOIN farms ON farms.id = ps.farm_id
        JOIN pucs ON pucs.id = ps.puc_id
        JOIN orchards ON orchards.id = ps.orchard_id
        JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
        LEFT JOIN pm_boms ON pm_boms.id = ps.pm_bom_id
        LEFT JOIN pm_boms_products ON pm_boms_products.pm_bom_id = ps.pm_bom_id
        LEFT JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
        LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
        LEFT JOIN plant_resources lines ON lines.id = ps.production_line_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
        WHERE ps.id = #{sequence_id}
      SQL
      hash = DB[query].first
      return nil if hash.nil?

      OpenStruct.new(hash)
    end

    def find_orchard_cultivar_group_and_farm(orchard_id)
      query = <<~SQL
        SELECT DISTINCT g.cultivar_group_code, f.id as farm_id
        FROM orchards o
        JOIN farms f ON f.id=o.farm_id
        JOIN cultivars c ON c.id = ANY (o.cultivar_ids)
        JOIN cultivar_groups g ON g.id=c.cultivar_group_id
        WHERE o.id=#{orchard_id}
        LIMIT 1
      SQL
      DB[query].first
    end

    def find_to_farm_orchards(cultivar_and_farm)
      query = <<~SQL
        SELECT DISTINCT o.id, f.farm_code || '_' || o.orchard_code  AS farm_orchard_code
        FROM orchards o
        JOIN farms f ON f.id=o.farm_id
        -- JOIN cultivars c ON c.id = ANY (o.cultivar_ids)
        -- JOIN cultivar_groups g ON g.id=c.cultivar_group_id
        -- where g.cultivar_group_code='#{cultivar_and_farm[:cultivar_group_code]}' AND f.id='#{cultivar_and_farm[:farm_id]}'
        where f.id='#{cultivar_and_farm[:farm_id]}'
        ORDER BY o.id ASC
      SQL
      DB[query].map { |s| [s[:farm_orchard_code], s[:id]] }
    end

    def for_select_template_commodity_marketing_varieties(commodity_id, cultivar_id = nil) # rubocop:disable Metrics/AbcSize
      ds = DB[:marketing_varieties]
           .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
           .join(:cultivars, id: :cultivar_id)
           .join(:cultivar_groups, id: :cultivar_group_id)
           .where(Sequel[:cultivar_groups][:commodity_id] => commodity_id)
      ds = ds.where(Sequel[:cultivars][:id] => cultivar_id) unless cultivar_id.nil_or_empty?
      ds.distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:marketing_varieties][:id],
          Sequel[:marketing_varieties][:marketing_variety_code]
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def for_selected_second_pm_products(subtype_code, fruit_sticker_pm_product_id)
      query = <<~SQL
        SELECT p.id, p.product_code
        FROM pm_products p
        JOIN pm_subtypes s on s.id = p.pm_subtype_id
        JOIN pm_types t on t.id = s.pm_type_id
        WHERE s.subtype_code = '#{subtype_code}' AND p.id != #{fruit_sticker_pm_product_id}
      SQL
      DB[query].map { |r| [r[:product_code], r[:id]] }
    end

    def find_deliveries(delivery_ids)
      query = <<~SQL
        SELECT DISTINCT d.*, o.orchard_code, c.cultivar_name, f.farm_code
        FROM rmt_deliveries d
        JOIN orchards o on o.id=d.orchard_id
        JOIN cultivars c on c.id=d.cultivar_id
        JOIN farms f on f.id=d.farm_id
        WHERE d.id IN (#{delivery_ids})
      SQL
      DB[query].all
    end

    def find_from_deliveries_cultivar(delivery_ids)
      query = <<~SQL
        SELECT DISTINCT o.id as orchard_id, c.id as cultivar_id, c.cultivar_name, f.farm_code || '_' || o.orchard_code AS farm_orchard_code
        FROM rmt_deliveries d
        JOIN orchards o on o.id=d.orchard_id
        JOIN cultivars c on c.id=d.cultivar_id
        JOIN farms f on f.id=d.farm_id
        WHERE d.id IN (#{delivery_ids})
      SQL
      DB[query].all
    end

    def find_bins(delivery_ids)
      query = <<~SQL
        SELECT DISTINCT *
        FROM rmt_bins b
        WHERE b.rmt_delivery_id IN (#{delivery_ids})
      SQL
      DB[query].all
      # all_hash(:rmt_bins, rmt_delivery_id: delivery_ids)
    end

    def bins_production_runs_allow_mixing?(delivery_ids)
      query = <<~SQL
        SELECT DISTINCT *
        FROM rmt_bins b
        JOIN production_runs r on r.id=b.production_run_tipped_id
        WHERE b.rmt_delivery_id IN (#{delivery_ids}) and r.allow_orchard_mixing is false
      SQL
      DB[query].all.empty? ? true : false
      # DB[:rmt_bins]
      #   .join(:production_runs, id: :production_run_tipped_id)
      #   .where(rmt_delivery_id: delivery_ids, allow_orchard_mixing: false)
      #   .count
      #   .zero?
    end

    def bin_bulk_update(delivery_ids, to_orchard, to_cultivar)
      DB[:rmt_bins].where(rmt_delivery_id: delivery_ids).update(orchard_id: to_orchard, cultivar_id: to_cultivar)
    end

    def scrapped_bin_bulk_update(params)
      # DB[:rmt_bins]
      #   .where(id: params[:pallets_selected])
      #   .update(scrap_remarks: params[:remarks],
      #           scrap_reason_id: params[:scrap_reason_id],
      #           scrapped_at: Time.now,
      #           scrapped: true,
      #           exit_ref: 'SCRAPPED',
      #           exit_ref_date_time: Time.now)
      upd = "UPDATE rmt_bins SET scrap_remarks = '#{params[:remarks]}', scrap_reason_id = #{params[:scrap_reason_id]},
             scrapped_at = '#{Time.now}', scrapped = true, exit_ref = 'SCRAPPED', exit_ref_date_time = '#{Time.now}',
             scrapped_bin_asset_number = bin_asset_number, bin_asset_number = null,
             scrapped_rmt_delivery_id = rmt_delivery_id, rmt_delivery_id = null
             WHERE id IN (#{params[:pallets_selected].join(',')});"
      DB[upd].update
    end

    def unscrapped_bin_bulk_update(params)
      # DB[:rmt_bins]
      #   .where(id: params[:pallets_selected])
      #   .update(scrapped: false,
      #           scrapped_at: nil,
      #           unscrapped_at: Time.now,
      #           exit_ref: nil,
      #           exit_ref_date_time: nil,
      #           scrap_remarks: nil,
      #           scrap_reason_id: nil)
      #
      # upd = ''
      upd = "UPDATE rmt_bins SET scrapped = false, scrapped_at = null, unscrapped_at = '#{Time.now}',
             exit_ref = null, exit_ref_date_time = null, scrap_remarks = '', scrap_reason_id = null,
             rmt_delivery_id = scrapped_rmt_delivery_id, scrapped_rmt_delivery_id = null
             WHERE id IN (#{params[:pallets_selected].join(',')});"
      params[:pallets_selected].each { |bin_id| upd << update_bin_asset_number(bin_id.to_i) }
      DB[upd].update
    end

    def update_bin_asset_number(bin_id)
      str = "UPDATE rmt_bins SET scrapped_bin_asset_number = null WHERE id = #{bin_id};"
      scrapped_bin_asset_number = DB[:rmt_bins].where(id: bin_id).get(:scrapped_bin_asset_number)
      str = "UPDATE rmt_bins SET bin_asset_number = '#{scrapped_bin_asset_number}', scrapped_bin_asset_number = null WHERE id = #{bin_id};" unless bin_asset_number_not_available(scrapped_bin_asset_number)
      str
    end

    def bin_asset_number_not_available(scrapped_bin_asset_number)
      return false if scrapped_bin_asset_number.nil_or_empty?

      query = <<~SQL
        SELECT EXISTS(
          SELECT id
          FROM rmt_bins
          WHERE exit_ref is null
            AND	bin_asset_number = '#{scrapped_bin_asset_number}')
      SQL
      DB[query].single_value
    end

    def get_scrap_reason_id(attrs)
      scrap_reason = attrs.gsub('_', ' ').upcase
      DB[:scrap_reasons].where(scrap_reason: scrap_reason).get(:id)
    end

    def find_reworks_runs_with(pallet_number)
      query = <<~SQL
        SELECT id FROM reworks_runs WHERE pallets_affected @> string_to_array('#{pallet_number}',',');
      SQL
      DB[query].all.map { |r| r[:id] }
    end

    def find_pallet_numbers(pallet_ids)
      select_values(:pallets, :pallet_number, id: pallet_ids)
    end

    def find_run_location_id(production_run_id)
      DB[:production_runs]
        .join(:plant_resources, id: :packhouse_resource_id)
        .where(Sequel[:production_runs][:id] => production_run_id)
        .get(Sequel[:plant_resources][:location_id])
    end

    def update_production_run(production_run_id, attrs)
      DB[:production_runs].where(id: production_run_id).update(attrs)
    end

    def production_run_allow_cultivar_mixing(production_run_id)
      DB[:production_runs].where(id: production_run_id).get(:allow_cultivar_mixing)
    end

    def production_run_allow_cultivar_group_mixing(production_run_id)
      DB[:production_runs].where(id: production_run_id).get(:allow_cultivar_group_mixing)
    end

    def in_stock_pallets?(pallet_numbers)
      DB[:pallets].where(pallet_number: pallet_numbers, in_stock: true).select_map(:pallet_number)
    end

    def includes_in_stock_pallets?(pallet_numbers)
      return false if pallet_numbers.nil_or_empty?

      query = "SELECT EXISTS( SELECT id FROM pallets WHERE in_stock AND	pallet_number IN ('#{pallet_numbers.join('\',\'')}'))"
      DB[query].single_value
    end

    def selected_deliveries(rmt_deliveries_ids)
      select_values(:rmt_deliveries, :id, id: rmt_deliveries_ids)
    end

    def deliveries_farms(delivery_ids)
      DB[:rmt_deliveries]
        .join(:farms, id: :farm_id)
        .where(Sequel[:rmt_deliveries][:id] => delivery_ids)
        .distinct(Sequel[:farms][:id])
        .select_map(Sequel[:farms][:id])
    end

    def deliveries_cultivar_group(cultivar_id)
      DB[:cultivars]
        .join(:cultivar_groups, id: :cultivar_group_id)
        .where(Sequel[:cultivars][:id] => cultivar_id)
        .get(:cultivar_group_code)
    end

    def deliveries_production_runs(delivery_ids, ignore_runs_that_allow_mixing = false)
      ds = DB[:rmt_bins]
           .join(:production_runs, id: :production_run_tipped_id)
           .where(rmt_delivery_id: delivery_ids)

      ds = ds.where(allow_orchard_mixing: false) if ignore_runs_that_allow_mixing
      ds.select_map(:production_run_tipped_id).uniq
    end

    def invalidates_marketing_varieties?(production_runs, cultivar_id)
      query = <<~SQL
         query = <<~SQL
          SELECT EXISTS(
           SELECT DISTINCT id FROM carton_labels WHERE production_run_id IN (#{production_runs.join(',')})
           AND marketing_variety_id NOT IN (
              SELECT DISTINCT marketing_variety_id FROM marketing_varieties_for_cultivars WHERE cultivar_id = #{cultivar_id}
           )
           UNION
           SELECT DISTINCT id FROM cartons WHERE production_run_id IN (#{production_runs.join(',')})
           AND marketing_variety_id NOT IN (
              SELECT DISTINCT marketing_variety_id FROM marketing_varieties_for_cultivars WHERE cultivar_id = #{cultivar_id}
           )
          UNION
           SELECT DISTINCT id FROM pallet_sequences WHERE production_run_id IN (#{production_runs.join(',')})
           AND marketing_variety_id NOT IN (
              SELECT DISTINCT marketing_variety_id FROM marketing_varieties_for_cultivars WHERE cultivar_id = #{cultivar_id}
           )
        )
      SQL
      DB[query].single_value
    end

    def update_delivery(delivery_id, attrs)
      DB[:rmt_deliveries].where(id: delivery_id).update(attrs)
    end

    def update_objects(objects_table_name, objects_ids, attrs)
      DB[objects_table_name.to_sym].where(id: objects_ids).update(attrs)
    end

    def changes_made_objects(objects_table_name, objects_ids)
      query = <<~SQL
        SELECT DISTINCT orchard_id, cultivar_id, cultivars.cultivar_name, farms.farm_code || '_' || orchards.orchard_code AS farm_orchard_code
        FROM #{objects_table_name} t
        JOIN orchards on orchards.id = t.orchard_id
        LEFT JOIN cultivars on cultivars.id = t.cultivar_id
        JOIN farms on farms.id = t.farm_id
        WHERE t.id IN (#{objects_ids})
      SQL
      DB[query].all
    end

    def change_objects_counts(delivery_ids, ignore_runs_that_allow_mixing = false) # rubocop:disable Metrics/AbcSize
      production_runs = deliveries_production_runs(delivery_ids, ignore_runs_that_allow_mixing)

      tipped_bins_query = <<~SQL
        SELECT COUNT(id) FROM rmt_bins WHERE production_run_tipped_id IN (#{production_runs.join(',')})
      SQL

      carton_labels_query = <<~SQL
        SELECT COUNT(id) FROM carton_labels WHERE production_run_id IN (#{production_runs.join(',')})
      SQL

      pallet_sequences_query = <<~SQL
        SELECT COUNT(id) FROM pallet_sequences WHERE production_run_id IN (#{production_runs.join(',')})
      SQL

      shipped_ps_query = <<~SQL
        SELECT COUNT(pallet_sequences.id) FROM pallets
        JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
        WHERE shipped AND production_run_id IN (#{production_runs.join(',')})
      SQL

      inspected_ps_query = <<~SQL
        SELECT COUNT(pallet_sequences.id) FROM pallets
        JOIN pallet_sequences ON pallets.id = pallet_sequences.pallet_id
        WHERE inspected AND production_run_id IN (#{production_runs.join(',')})
      SQL

      { deliveries: delivery_ids.count,
        production_runs: production_runs.count,
        tipped_bins: DB[tipped_bins_query].single_value,
        carton_labels: DB[carton_labels_query].single_value,
        pallet_sequences: DB[pallet_sequences_query].single_value,
        shipped_pallet_sequences: DB[shipped_ps_query].single_value,
        inspected_pallet_sequences: DB[inspected_ps_query].single_value }
    end

    def carton_scrap_attributes(carton_id)
      query = <<~SQL
        SELECT cartons.scrapped,cartons.scrapped_at,cartons.scrapped_reason,cartons.scrapped_sequence_id,
               cartons.pallet_sequence_id, pallet_sequences.pallet_number, pallet_sequences.pallet_id
        FROM cartons
        LEFT JOIN pallet_sequences ON pallet_sequences.id = cartons.pallet_sequence_id
        WHERE cartons.id = ?
      SQL
      DB[query, carton_id].first
    end

    def find_sequence_farm_attrs(sequence_id)
      query = <<~SQL
        SELECT farm_id, cultivar_id
        FROM pallet_sequences
        WHERE pallet_sequences.id = ?
      SQL
      DB[query, sequence_id].first
    end

    def invalidates_sequence_marketing_varieties?(args)
      query = <<~SQL
        SELECT EXISTS(
           SELECT pallet_sequences.id FROM pallet_sequences
           WHERE pallet_sequences.id = #{args[:pallet_sequence_id]}
           AND marketing_variety_id NOT IN (
              SELECT DISTINCT marketing_varieties.id
              FROM marketing_varieties
              JOIN marketing_varieties_for_cultivars ON marketing_varieties_for_cultivars.marketing_variety_id = marketing_varieties.id
              JOIN cultivars ON cultivars.id = marketing_varieties_for_cultivars.cultivar_id
              JOIN cultivar_groups ON cultivar_groups.id = cultivars.cultivar_group_id
              WHERE cultivars.id = #{args[:cultivar_id]}
           )
        )
      SQL
      DB[query].single_value
    end

    def rmt_bins_for_nett_recalculation
      DB[:rmt_bins]
        .exclude(gross_weight: nil)
        .select(:id,
                :qty_inner_bins,
                :rmt_inner_container_material_id,
                :rmt_inner_container_type_id,
                :rmt_container_type_id,
                :gross_weight)
        .all
    end

    def sequence_carton_equals_pallet?(pallet_sequence_id)
      carton_id = sequence_carton_id(pallet_sequence_id)
      carton_label_id = get_value(:cartons, :carton_label_id, id: carton_id)

      get(:carton_labels, carton_label_id, :carton_equals_pallet)
    end

    def sequence_carton_id(pallet_sequence_id)
      # Get any carton matching the sequence:
      carton_id = DB[:cartons].where(pallet_sequence_id: pallet_sequence_id).get(:id)

      return carton_id unless carton_id.nil_or_empty?

      get(:pallet_sequences, pallet_sequence_id, :scanned_from_carton_id)
    end

    def packhouse_location_id_for_pallet(pallet_id)
      DB[:plant_resources].where(id: DB[:pallets]
                                       .where(id: pallet_id)
                                       .get(:plt_packhouse_resource_id)).get(:location_id)
    end

    def repacked_from_pallet_id_for_pallet(pallet_id)
      DB[:pallet_sequences].where(pallet_id: pallet_id).get(:repacked_from_pallet_id)
    end

    def restore_repacked_pallet(pallet_id, original_pallet_id)
      sequence_ids = select_values(:pallet_sequences, :id, pallet_id: pallet_id)
      original_sequence_ids = select_values(:pallet_sequences, :id, scrapped_from_pallet_id: original_pallet_id)
      return failed_response("Pallet #{pallet_id} or #{original_pallet_id} is missing sequences") if sequence_ids.empty? || original_sequence_ids.empty?

      update_pallet(pallet_id,
                    { scrapped: true, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_RESTORE_REPACKED_PALLET })
      update_pallet_sequence(sequence_ids,
                             { pallet_id: nil, scrapped_from_pallet_id: pallet_id, scrapped_at: Time.now, exit_ref: AppConst::PALLET_EXIT_REF_RESTORE_REPACKED_PALLET })

      update_pallet(original_pallet_id,
                    { scrapped: false, scrapped_at: nil, exit_ref: nil })
      update_pallet_sequence(original_sequence_ids,
                             { pallet_id: original_pallet_id, scrapped_from_pallet_id: nil, scrapped_at: nil, exit_ref: nil })

      ok_response
    end

    def details_for_production_run(production_run_id)
      query = <<~SQL
        SELECT production_runs.id, fn_production_run_code(production_runs.id) AS production_run_code,
        production_runs.allow_orchard_mixing,
        production_runs.allow_cultivar_mixing,
        production_runs.allow_cultivar_group_mixing,
        production_runs.active_run_stage,
        production_runs.started_at,
        production_run_stats.bins_tipped, COALESCE(production_run_stats.bins_tipped_weight, 0) AS bins_tipped_weight,
        production_run_stats.carton_labels_printed,
        production_run_stats.cartons_verified, production_run_stats.cartons_verified_weight,
        production_run_stats.pallets_palletized_full, production_run_stats.pallets_palletized_partial,
        production_run_stats.pallet_weight,
        production_run_stats.inspected_pallets,
        production_run_stats.rebins_created, production_run_stats.rebins_weight,
        production_runs.puc_id,
        production_runs.orchard_id,
        farms.farm_code,
        pucs.puc_code,
        orchards.orchard_code,
        production_runs.cultivar_group_id,
        cultivar_groups.cultivar_group_code,
        production_runs.cultivar_id,
        cultivars.cultivar_name,
        packhouses.plant_resource_code AS packhouse_code,
        production_runs.re_executed_at,
        lines.plant_resource_code AS line_code,
        (SELECT COUNT(DISTINCT pallet_id) FROM pallet_sequences WHERE production_run_id = production_runs.id AND verified) AS verified_pallets,
        COALESCE((SELECT SUM(COALESCE(standard_product_weights.nett_weight, 0))
             FROM cartons
             JOIN carton_labels ON carton_labels.id = cartons.carton_label_id
             LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
             LEFT JOIN cultivar_groups ON cultivar_groups.id = cultivars.cultivar_group_id
             LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
             LEFT OUTER JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id
               AND standard_product_weights.standard_pack_id = carton_labels.standard_pack_code_id
             WHERE production_run_id = production_runs.id
            ), 0) AS carton_weight
        FROM production_runs
        LEFT JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
        LEFT JOIN cultivars ON cultivars.id = production_runs.cultivar_id
        JOIN plant_resources packhouses ON packhouses.id = production_runs.packhouse_resource_id
        JOIN plant_resources lines ON lines.id = production_runs.production_line_id
        JOIN production_run_stats ON production_run_stats.production_run_id = production_runs.id
        JOIN farms ON farms.id = production_runs.farm_id
        LEFT JOIN orchards ON orchards.id = production_runs.orchard_id
        JOIN pucs ON pucs.id = production_runs.puc_id
        WHERE production_runs.id = #{production_run_id}
      SQL

      DB[query].first
    end

    def production_run_objects(production_run_id)
      {
        tipped_bin_ids: select_values(:rmt_bins, :id, production_run_tipped_id: production_run_id),
        carton_label_ids: select_values(:carton_labels, :id, production_run_id: production_run_id),
        pallet_sequence_ids: select_values(:pallet_sequences, :id, production_run_id: production_run_id)
      }
    end

    def find_rmt_bin_column_ids(column, where: {}, exclude: {})
      DB[:rmt_bins]
        .where(where)
        .exclude(exclude)
        .distinct
        .select_map(column.to_sym)
    end

    def details_for_rmt_delivery(rmt_delivery_id)
      query = <<~SQL
        SELECT rmt_deliveries.id, rmt_deliveries.farm_id, rmt_deliveries.orchard_id, cultivars.cultivar_group_id,
               rmt_deliveries.cultivar_id, farms.farm_code, orchards.orchard_code, cultivar_groups.cultivar_group_code,
               cultivars.cultivar_name
        FROM rmt_deliveries
        JOIN farms ON farms.id = rmt_deliveries.farm_id
        JOIN orchards ON orchards.id = rmt_deliveries.orchard_id
        JOIN cultivars ON cultivars.id = rmt_deliveries.cultivar_id
        LEFT JOIN cultivar_groups ON cultivar_groups.id = cultivars.cultivar_group_id
        WHERE rmt_deliveries.id = #{rmt_delivery_id}
      SQL

      DB[query].first
    end

    def pallet_requires_material_owner?(pallet_number)
      oldest_sequence = DB[:pallet_sequences]
                        .where(pallet_number: pallet_number)
                        .where(pallet_sequence_number: oldest_sequence_number(pallet_number))
                        .select(:standard_pack_code_id, :grade_id)
                        .first
      return false if oldest_sequence.nil_or_empty?

      ProductionApp::ProductSetupRepo.new.requires_material_owner?(oldest_sequence[:standard_pack_code_id], oldest_sequence[:grade_id])
    end

    def carton_labels_on_pallet_sequence(carton_labels)
      DB[:cartons]
        .where(carton_label_id: carton_labels)
        .exclude(pallet_sequence_id: nil, scrapped_sequence_id: nil)
        .select_map(:carton_label_id)
    end

    def scrapped_carton_labels(carton_labels)
      DB[:cartons]
        .where(carton_label_id: carton_labels)
        .where(scrapped: true)
        .select_map(:carton_label_id)
    end
  end
end
