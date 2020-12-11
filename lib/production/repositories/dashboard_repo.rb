# frozen_string_literal: true

module ProductionApp
  class DashboardRepo < BaseRepo # rubocop:disable Metrics/ClassLength
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

    def production_runs(line)
      and_clause = if line.nil_or_empty?
                     ''
                   else
                     line_id = DB[:plant_resources].where(plant_resource_code: line).get(:id)
                     "AND production_line_id = #{line_id}"
                   end
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
             JOIN carton_labels ON carton_labels.id = cartons.carton_label_id
             LEFT JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
                 LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
             LEFT OUTER JOIN standard_product_weights ON standard_product_weights.commodity_id = commodities.id
               AND standard_product_weights.standard_pack_id = carton_labels.standard_pack_code_id
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
        #{and_clause}
        ORDER BY plant_resources2.plant_resource_code, production_runs.tipping
      SQL

      DB[query].all
    end

    def tm_for_run(id)
      query = <<~SQL
        SELECT target_market_groups.target_market_group_name AS packed_tm_group,
        COUNT(cartons.id) AS no_cartons
        FROM cartons
        JOIN carton_labels ON carton_labels.id = cartons.carton_label_id
        JOIN target_market_groups ON target_market_groups.id = carton_labels.packed_tm_group_id
        WHERE production_run_id = ?
        GROUP BY target_market_groups.target_market_group_name
        ORDER BY target_market_groups.target_market_group_name
      SQL

      DB[query, id].all
    end

    def shipped_loads_per_week
      query = <<~SQL
        SELECT
          to_char(loads.shipped_at, 'IW'::text)::integer AS load_week,
          COUNT(*)
        FROM loads
        WHERE shipped
        GROUP BY 1
      SQL

      Hash[DB[query].select_map(%i[load_week no_shipped])]
    end

    def shipped_loads_per_day
      query = <<~SQL
        SELECT
          loads.shipped_at::date AS load_day,
          COUNT(*)
        FROM loads
        WHERE shipped
        GROUP BY 1
      SQL

      Hash[DB[query].select_map(%i[load_day no_shipped])]
    end

    def loads_per_week
      query = <<~SQL
        SELECT load_year, load_week, pol, pod, packed_tm_group, SUM(allocated) AS allocated, SUM(shipped) AS shipped,
               MIN(load_day) AS from_date, MAX(load_day) AS to_date, COUNT(DISTINCT load_id) AS no_loads
        FROM (
          SELECT
          DISTINCT pallets.pallet_number,
              pol_port.port_code AS pol,
              pod_port.port_code AS pod,
            target_market_groups.target_market_group_name AS packed_tm_group,
            to_char(COALESCE(pallets.shipped_at, pallets.allocated_at, loads.created_at), 'YYYY'::text)::integer AS load_year,
            to_char(COALESCE(pallets.shipped_at, pallets.allocated_at, loads.created_at), 'IW'::text)::integer AS load_week,
            COALESCE(pallets.shipped_at, pallets.allocated_at, loads.created_at)::date AS load_day,
            pallets.load_id,
            CASE WHEN pallets.allocated AND NOT pallets.shipped THEN
              1
            ELSE
              0
            END AS allocated,
            CASE WHEN pallets.shipped THEN
              1
            ELSE
              0
            END AS shipped
          FROM pallets
          JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
          JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
          JOIN loads ON loads.id = pallets.load_id
          JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
          JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
          JOIN ports pol_port ON pol_port.id = pol_voyage_ports.port_id
          JOIN ports pod_port ON pod_port.id = pod_voyage_ports.port_id
        ) sub_pallets
        GROUP BY load_year, load_week, pol, pod, packed_tm_group
        ORDER BY load_year DESC, load_week DESC, pol, pod, packed_tm_group
      SQL

      DB[query].all.group_by { |r| r[:load_week] }
    end

    def loads_per_day
      query = <<~SQL
        SELECT load_day, pol, pod, packed_tm_group, SUM(allocated) AS allocated, SUM(shipped) AS shipped, COUNT(DISTINCT load_id) AS no_loads
        FROM (
          SELECT
          DISTINCT pallets.pallet_number,
              pol_port.port_code AS pol,
              pod_port.port_code AS pod,
            target_market_groups.target_market_group_name AS packed_tm_group,
            COALESCE(pallets.shipped_at, pallets.allocated_at, loads.created_at)::date AS load_day,
            pallets.load_id,
            CASE WHEN pallets.allocated AND NOT pallets.shipped THEN
              1
            ELSE
              0
            END AS allocated,
            CASE WHEN pallets.shipped THEN
              1
            ELSE
              0
            END AS shipped
          FROM pallets
          JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
          JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
          JOIN loads ON loads.id = pallets.load_id
          JOIN voyage_ports pol_voyage_ports ON pol_voyage_ports.id = loads.pol_voyage_port_id
          JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
          JOIN ports pol_port ON pol_port.id = pol_voyage_ports.port_id
          JOIN ports pod_port ON pod_port.id = pod_voyage_ports.port_id
        ) sub_pallets
        GROUP BY load_day, pol, pod, packed_tm_group
        ORDER BY load_day DESC, pol, pod, packed_tm_group
      SQL

      DB[query].all.group_by { |r| r[:load_day] }
    end

    def pallets_in_stock
      query = <<~SQL
        SELECT
          target_market_groups.target_market_group_name AS packed_tm_group,
          cultivars.cultivar_name,
          standard_pack_codes.standard_pack_code,
          COUNT(*) AS pallet_count
        FROM pallets
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
        JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
        JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
        JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
        WHERE pallets.in_stock AND NOT pallets.allocated
        GROUP BY target_market_groups.target_market_group_name, cultivars.cultivar_name, standard_pack_codes.standard_pack_code
        ORDER BY target_market_groups.target_market_group_name, cultivars.cultivar_name, standard_pack_codes.standard_pack_code
      SQL

      DB[query].all
    end

    def pallets_in_stock_per_size
      query = <<~SQL
        SELECT
          target_market_groups.target_market_group_name AS packed_tm_group,
          cultivars.cultivar_name,
          standard_pack_codes.standard_pack_code,
          CASE
              WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
              ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
          END AS count_swap_rule,
          COUNT(*) AS pallet_count
        FROM pallets
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
        JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
        JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
        JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
        LEFT JOIN commodities ON commodities.id = cultivars.commodity_id
        LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
        WHERE pallets.in_stock AND NOT pallets.allocated
        GROUP BY target_market_groups.target_market_group_name, cultivars.cultivar_name, standard_pack_codes.standard_pack_code,
              CASE
                WHEN commodities.code::text = 'SC'::text THEN concat_ws('/'::text, fruit_size_references.size_reference, std_fruit_size_counts.size_count_interval_group)
                ELSE concat_ws('/'::text, fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack)
              END
        ORDER BY target_market_groups.target_market_group_name, cultivars.cultivar_name, standard_pack_codes.standard_pack_code
      SQL

      DB[query].all
    end

    def delivery_cultivars_per_week
      query = <<~SQL
        SELECT
          to_char(rmt_bins.bin_received_date_time, 'IW'::text)::integer AS delivery_week,
          cultivars.cultivar_name,
          SUM(CASE WHEN rmt_bins.bin_tipped THEN rmt_bins.qty_bins ELSE 0 END) AS qty_tipped,
          SUM(rmt_bins.qty_bins) AS qty_bins,
          COUNT(DISTINCT rmt_bins.rmt_delivery_id) AS no_deliveries
        FROM rmt_bins
        LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
        WHERE NOT rmt_bins.is_rebin
        GROUP BY 1, 2
      SQL

      DB[query].all.group_by { |r| r[:delivery_week] }
    end

    def delivery_cultivars_per_day
      query = <<~SQL
        SELECT
          rmt_bins.bin_received_date_time::date AS delivery_day,
          cultivars.cultivar_name,
          SUM(CASE WHEN rmt_bins.bin_tipped THEN rmt_bins.qty_bins ELSE 0 END) AS qty_tipped,
          SUM(rmt_bins.qty_bins) AS qty_bins,
          COUNT(DISTINCT rmt_bins.rmt_delivery_id) AS no_deliveries
        FROM rmt_bins
        LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
        WHERE NOT rmt_bins.is_rebin
        GROUP BY 1, 2
      SQL

      DB[query].all.group_by { |r| r[:delivery_day] }
    end

    def deliveries_per_week
      query = <<~SQL
        SELECT
          -- rmt_deliveries.date_delivered,
          to_char(rmt_bins.bin_received_date_time, 'YYYY'::text)::integer AS delivery_year,
          to_char(rmt_bins.bin_received_date_time, 'IW'::text)::integer AS delivery_week,
          farms.farm_code,
          pucs.puc_code,
          orchards.orchard_code,
          cultivars.cultivar_name,
          SUM(CASE WHEN rmt_bins.bin_tipped THEN rmt_bins.qty_bins ELSE 0 END) AS qty_tipped,
          SUM(rmt_bins.qty_bins) AS qty_bins,
          COUNT(DISTINCT rmt_bins.rmt_delivery_id) AS no_deliveries
        FROM rmt_bins
        LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
        LEFT JOIN farms ON farms.id = rmt_bins.farm_id
        LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
        LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
        WHERE NOT rmt_bins.is_rebin
        GROUP BY to_char(rmt_bins.bin_received_date_time, 'YYYY'::text)::integer,
          to_char(rmt_bins.bin_received_date_time, 'IW'::text)::integer,
          farms.farm_code,
          pucs.puc_code,
          orchards.orchard_code,
          cultivars.cultivar_name
        ORDER BY to_char(rmt_bins.bin_received_date_time, 'YYYY'::text)::integer DESC,
          to_char(rmt_bins.bin_received_date_time, 'IW'::text)::integer DESC,
          farms.farm_code,
          pucs.puc_code,
          orchards.orchard_code,
          cultivars.cultivar_name
      SQL

      DB[query].all.group_by { |r| r[:delivery_week] }
    end

    def deliveries_per_day
      query = <<~SQL
        SELECT
          -- rmt_deliveries.date_delivered,
          rmt_bins.bin_received_date_time::date AS bin_received_date,
          farms.farm_code,
          pucs.puc_code,
          orchards.orchard_code,
          cultivars.cultivar_name,
          SUM(CASE WHEN rmt_bins.bin_tipped THEN rmt_bins.qty_bins ELSE 0 END) AS qty_tipped,
          SUM(rmt_bins.qty_bins) AS qty_bins,
          COUNT(DISTINCT rmt_bins.rmt_delivery_id) AS no_deliveries
        FROM rmt_bins
        LEFT JOIN cultivars ON cultivars.id = rmt_bins.cultivar_id
        LEFT JOIN farms ON farms.id = rmt_bins.farm_id
        LEFT JOIN pucs ON pucs.id = rmt_bins.puc_id
        LEFT JOIN orchards ON orchards.id = rmt_bins.orchard_id
        WHERE NOT rmt_bins.is_rebin
        GROUP BY rmt_bins.bin_received_date_time::date,
          farms.farm_code,
          pucs.puc_code,
          orchards.orchard_code,
          cultivars.cultivar_name
        ORDER BY rmt_bins.bin_received_date_time::date DESC,
          farms.farm_code,
          pucs.puc_code,
          orchards.orchard_code,
          cultivars.cultivar_name
      SQL

      DB[query].all.group_by { |r| r[:bin_received_date] }
    end

    def last_day_for_summary
      query = 'SELECT MAX(carton_labels.created_at)::date AS dat FROM carton_labels JOIN cartons ON cartons.carton_label_id = carton_labels.id'
      d1 = DB[query].get(:dat)
      query = 'SELECT MAX(created_at)::date AS dat FROM pallet_sequences'
      d2 = DB[query].get(:dat)
      [d1, d2].max
    end

    def carton_summary
      query = <<~SQL
            SELECT
            c.carton_label_created_at::date AS date,
            to_char(c.carton_label_created_at, 'IW'::text)::integer AS week,
            c.packhouse AS packhouse_code,
            c.cultivar_code,
            c.standard_pack_code,
            c.scrapped,
            COUNT(DISTINCT carton_id) AS total_verified_carton_qty

        FROM (
            SELECT
                cartons.id as carton_id,
                carton_labels.created_at AS carton_label_created_at,
                packhouses.plant_resource_code AS packhouse,
                cultivars.cultivar_code AS cultivar_code,
                standard_pack_codes.standard_pack_code,
                cartons.scrapped
            FROM carton_labels
            JOIN cartons ON carton_labels.id = cartons.carton_label_id
            JOIN production_runs ON production_runs.id = carton_labels.production_run_id
            JOIN plant_resources packhouses ON packhouses.id = carton_labels.packhouse_resource_id
            JOIN cultivars ON cultivars.id = carton_labels.cultivar_id
            JOIN standard_pack_codes ON standard_pack_codes.id = carton_labels.standard_pack_code_id
             ) c
        GROUP BY
            c.carton_label_created_at::date,
            to_char(c.carton_label_created_at, 'IW'::text)::integer,
            c.packhouse,
            c.cultivar_code,
            c.standard_pack_code,
            c.scrapped

        ORDER BY c.carton_label_created_at::date DESC
      SQL
      DB[query].all
    end

    def pallet_summary
      query = <<~SQL
        SELECT
            ps.created_at::date AS date,
            to_char(ps.created_at, 'IW'::text)::integer AS week,
            packhouses.plant_resource_code AS packhouse_code,
            cultivars.cultivar_code,
            standard_pack_codes.standard_pack_code,

            COUNT(DISTINCT CASE WHEN l.shipped THEN p.load_id END) AS shipped_load_qty,
            COUNT(DISTINCT CASE WHEN NOT l.shipped THEN p.load_id END) AS allocated_load_qty,

            COUNT(DISTINCT CASE WHEN l.shipped THEN p.id END) AS shipped_pallet_qty,
            COUNT(DISTINCT CASE WHEN NOT l.shipped THEN p.id END) AS allocated_pallet_qty,
            COUNT(DISTINCT CASE WHEN p.load_id IS NULL AND ps.verified THEN p.id END) AS verified_pallet_qty,
            COUNT(DISTINCT CASE WHEN p.load_id IS NULL AND NOT ps.verified THEN p.id END) AS unverified_pallet_qty,
            COUNT(DISTINCT p.id) AS total_pallet_qty,

            SUM(CASE WHEN l.shipped THEN ps.carton_quantity ELSE 0 END) AS shipped_carton_qty,
            SUM(CASE WHEN NOT l.shipped THEN ps.carton_quantity ELSE 0 END) AS allocated_carton_qty,
            SUM(CASE WHEN p.load_id IS NULL AND ps.verified THEN ps.carton_quantity ELSE 0 END) AS verified_carton_qty,
            SUM(CASE WHEN p.load_id IS NULL AND NOT ps.verified THEN ps.carton_quantity ELSE 0 END) AS unverified_carton_qty,
            SUM(ps.carton_quantity) AS total_carton_qty

        FROM pallet_sequences ps
        JOIN pallets p ON p.id = ps.pallet_id
        LEFT JOIN loads l ON p.load_id = l.id
        JOIN cultivars ON cultivars.id = ps.cultivar_id
        LEFT JOIN plant_resources packhouses ON packhouses.id = ps.packhouse_resource_id
        JOIN standard_pack_codes ON standard_pack_codes.id = ps.standard_pack_code_id

        GROUP BY
            ps.created_at::date,
            to_char(ps.created_at, 'IW'::text)::integer,
            packhouses.plant_resource_code,
            cultivars.cultivar_code,
            standard_pack_codes.standard_pack_code
      SQL
      DB[query].all
    end

    def device_allocation(run_id, plant_resource_id)
      query = <<~SQL
        SELECT plant_resources.plant_resource_code,
        farms.farm_code,
        pucs.puc_code,
        orchards.orchard_code,
        cultivars.cultivar_code,
        grades.grade_code,
        marketing_varieties.marketing_variety_code,
        standard_pack_codes.standard_pack_code,
        fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
        fruit_size_references.size_reference AS size_ref,
        target_market_groups.target_market_group_name AS packed_tm_group
        FROM product_resource_allocations
        JOIN production_runs ON production_runs.id = product_resource_allocations.production_run_id
        JOIN product_setups ON product_setups.id = product_resource_allocations.product_setup_id
        JOIN farms ON farms.id = production_runs.farm_id
        JOIN pucs ON pucs.id = production_runs.puc_id
        LEFT JOIN orchards ON orchards.id = production_runs.orchard_id
        LEFT JOIN cultivars ON cultivars.id = production_runs.cultivar_id
        JOIN grades ON grades.id = product_setups.grade_id
        JOIN target_market_groups ON target_market_groups.id = product_setups.packed_tm_group_id
        JOIN marketing_varieties ON marketing_varieties.id = product_setups.marketing_variety_id
        JOIN standard_pack_codes ON standard_pack_codes.id = product_setups.standard_pack_code_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = product_setups.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = product_setups.fruit_actual_counts_for_pack_id
        JOIN plant_resources ON plant_resources.id = product_resource_allocations.plant_resource_id
        WHERE production_run_id = ?
          AND plant_resource_id = ?
      SQL
      DB[query, run_id, plant_resource_id].all
    end
  end
end
