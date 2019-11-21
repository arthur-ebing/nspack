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
                 COALESCE(reworks_runs.pallets_scrapped, reworks_runs.pallets_unscrapped, reworks_runs.pallets_selected) AS pallets_selected,
                 reworks_runs.pallets_affected, COALESCE(reworks_runs.changes_made -> 'pallets' ->> 'pallet_number', '') AS pallet_number,
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

    def affected_pallet_numbers(sequence_ids, attrs)
      DB[:pallet_sequences].where(id: sequence_ids).where(attrs).map { |p| p[:pallet_number] }
    end

    def update_reworks_run_pallets(pallet_numbers, attrs, reworks_run_booleans)
      DB[:pallets].where(pallet_number: pallet_numbers).update(attrs)
      upd = "UPDATE pallet_sequences SET scrapped_from_pallet_id = pallet_id, pallet_id = null, scrapped_at = '#{Time.now}', exit_ref = '#{AppConst::PALLET_EXIT_REF_SCRAPPED}' WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}');" if reworks_run_booleans[:scrap_pallets]
      upd = "UPDATE pallet_sequences SET scrapped_from_pallet_id = null, pallet_id = scrapped_from_pallet_id, scrapped_at = null, exit_ref = null WHERE pallet_number IN ('#{pallet_numbers.join('\',\'')}');" if reworks_run_booleans[:unscrap_pallets]
      DB[upd].update
    end

    def update_reworks_run_pallet_sequences(pallet_numbers, pallet_sequence_ids, pallet_sequence_attrs)
      upd = "UPDATE pallets SET pallet_format_id = pallet_sequences.pallet_format_id FROM pallet_sequences
             WHERE pallets.id = pallet_sequences.pallet_id AND pallets.pallet_number IN ('#{pallet_numbers.join('\',\'')}');"
      DB[upd].update
      DB[:pallet_sequences].where(id: pallet_sequence_ids).update(pallet_sequence_attrs)
    end

    def reworks_run_clone_pallet(pallet_numbers)
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

    def find_product_setup_id(sequence_id)
      DB[:pallet_sequences]
        .join(:product_resource_allocations, id: :product_resource_allocation_id)
        .where(Sequel[:pallet_sequences][:id] => sequence_id)
        .get(:product_setup_id)
    end

    def reworks_run_pallet_quantities(pallet_number)
      query = <<~SQL
        SELECT pallet_sequence_number, seq_carton_qty
        FROM vw_pallet_sequence_flat
        WHERE pallet_number = '#{pallet_number}'
        ORDER BY pallet_sequence_number
      SQL
      DB[query].order(:puc_code).select_map(%i[pallet_sequence_number seq_carton_qty])
    end

    def edit_carton_quantities(id, seq_carton_qty)
      update(:pallet_sequences, id, carton_quantity: seq_carton_qty)
    end

    def pallet_seq_carton_quantity(pallet_id)
      DB[:pallet_sequences].where(pallet_id: pallet_id).select_map(:carton_quantity)
    end
  end
end
