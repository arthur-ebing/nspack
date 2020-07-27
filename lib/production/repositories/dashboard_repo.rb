# frozen_string_literal: true

module ProductionApp
  class DashboardRepo < BaseRepo
    def palletizing_bay_states
      query = <<~SQL
        SELECT b.id, r.plant_resource_code,
        r.description,
        b.palletizing_robot_code,
        b.scanner_code,
        b.palletizing_bay_resource_id,
        b.current_state,
        b.pallet_sequence_id,
        b.determining_carton_id,
        b.last_carton_id,
        b.updated_at,
        ps.carton_quantity AS seq_qty,
        p.carton_quantity AS pallet_qty,
        cartons_per_pallet.cartons_per_pallet,
        p.pallet_number,
        concat_ws(' ', contract_workers.first_name, contract_workers.surname) AS palletizer,
        (p.carton_quantity::numeric / cartons_per_pallet.cartons_per_pallet::numeric * 100)::numeric(5,2) AS percentage,
        commodities.code AS commodity,
        marketing_varieties.marketing_variety_code AS variety,
        fn_edi_size_count(standard_pack_codes.use_size_ref_for_edi,
                          commodities.use_size_ref_for_edi,
                          fruit_size_references.edi_out_code,
                          fruit_size_references.size_reference,
                          fruit_actual_counts_for_packs.actual_count_for_pack) AS size
        FROM palletizing_bay_states b
        LEFT OUTER JOIN plant_resources r ON r.id = b.palletizing_bay_resource_id
        LEFT OUTER JOIN pallet_sequences ps ON ps.id = b.pallet_sequence_id
        LEFT OUTER JOIN pallets p ON p.id = ps.pallet_id
        LEFT OUTER JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
        LEFT OUTER JOIN contract_workers ON contract_workers.id = ps.contract_worker_id
        LEFT OUTER JOIN cultivars ON cultivars.id = ps.cultivar_id
        LEFT OUTER JOIN commodities ON commodities.id = cultivars.commodity_id
        LEFT OUTER JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
        LEFT OUTER JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
        LEFT OUTER JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
        LEFT OUTER JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id
        ORDER BY b.palletizing_robot_code, b.scanner_code
      SQL

      DB[query].all
    end

    def production_runs
      query = <<~SQL
        SELECT production_runs.id, fn_production_run_code(production_runs.id) AS production_run_code,
        production_runs.active_run_stage,
        production_runs.started_at,
        production_run_stats.bins_tipped,
        COALESCE(production_run_stats.bins_tipped_weight, 0) AS bins_tipped_weight,
        production_run_stats.carton_labels_printed,
        production_run_stats.cartons_verified, production_run_stats.cartons_verified_weight,
        production_run_stats.pallets_palletized_full, production_run_stats.pallets_palletized_partial,
        production_run_stats.pallet_weight,
        production_run_stats.inspected_pallets, production_run_stats.rebins_created, production_run_stats.rebins_weight,
        farms.farm_code,
        pucs.puc_code,
        orchards.orchard_code,
        cultivar_groups.cultivar_group_code,
        plant_resources.plant_resource_code AS packhouse_code,
        production_runs.re_executed_at,
        plant_resources2.plant_resource_code AS line_code,
        (SELECT COUNT(DISTINCT pallet_id) FROM pallet_sequences WHERE production_run_id = production_runs.id AND verified) AS verified_pallets,
        COALESCE((SELECT SUM(COALESCE(standard_product_weights.nett_weight, 0))
             FROM cartons
             LEFT JOIN cultivars ON cultivars.id = cartons.cultivar_id
                 LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
             LEFT OUTER JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id
               AND standard_product_weights.standard_pack_id = cartons.standard_pack_code_id
             WHERE production_run_id = production_runs.id
            ), 0) AS carton_weight
        FROM production_runs
        LEFT JOIN cultivar_groups ON cultivar_groups.id = production_runs.cultivar_group_id
        JOIN plant_resources ON plant_resources.id = production_runs.packhouse_resource_id
        JOIN plant_resources plant_resources2 ON plant_resources2.id = production_runs.production_line_id
        JOIN production_run_stats ON production_run_stats.production_run_id = production_runs.id
        JOIN farms ON farms.id = production_runs.farm_id
        LEFT JOIN orchards ON orchards.id = production_runs.orchard_id
        JOIN pucs ON pucs.id = production_runs.puc_id
        WHERE running
        ORDER BY plant_resources2.plant_resource_code, production_runs.tipping
      SQL

      DB[query].all
    end

    def tm_for_run(id)
      query = <<~SQL
        SELECT target_market_groups.target_market_group_name AS packed_tm_group,
        COUNT(cartons.id) AS no_cartons
        FROM cartons
        JOIN target_market_groups ON target_market_groups.id = cartons.packed_tm_group_id
        WHERE production_run_id = ?
        GROUP BY target_market_groups.target_market_group_name
        ORDER BY target_market_groups.target_market_group_name
      SQL

      DB[query, id].all
    end
  end
end
