# frozen_string_literal: true

module EdiApp
  class HcsOutRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    def prepare_depot_pallet_cartons(load_id) # rubocop:disable Metrics/AbcSize
      # Create missing depot pallet carton numbers
      query = <<~SQL
        SELECT pallet_sequences.id, pallet_sequences.carton_quantity,
        COUNT(depot_cartons.depot_carton_number) as no_depot_cartons
        FROM pallet_sequences
        JOIN pallets ON pallets.id = pallet_sequences.pallet_id
        LEFT JOIN depot_cartons ON depot_cartons.pallet_sequence_id = pallet_sequences.id
        WHERE pallets.load_id = ?
          AND pallets.depot_pallet
        GROUP BY pallet_sequences.id, pallet_sequences.carton_quantity
      SQL

      DB[query, load_id].each do |row|
        next if row[:carton_quantity] == row[:no_depot_cartons]

        if row[:carton_quantity] > row[:no_depot_cartons]
          doc_seq = DocumentSequence.new('depot_carton_number')
          (row[:carton_quantity] - row[:no_depot_cartons]).times do
            no = DB[doc_seq.next_sequence_sql_as_seq].get(:seq)
            create(:depot_cartons, pallet_sequence_id: row[:id], depot_carton_number: no)
          end
        else
          cnt = row[:no_depot_cartons] - row[:carton_quantity]
          nos = DB[:depot_cartons]
                .where(pallet_sequence_id: row[:id])
                .reverse(:depot_carton_number)
                .limit(cnt).select_map(:depot_carton_number)
          DB[:depot_cartons]
            .where(pallet_sequence_id: row[:id], depot_carton_number: nos)
            .delete
        end
      end
    end

    def calculate_ucr_for_load(load_id)
      # suffix = record.no_loads_on_order.to_i > 1 ? 'M' : 'S'
      # ucr = "#{record.shipped_date_time[3,1]}ZA01507472CDEL#{order.order_number}#{suffix}"
      shipped_at = DB[:loads].where(id: load_id).get(:shipped_at)
      order_id = DB[:orders_loads].where(load_id: load_id).get(:order_id)
      cnt = DB[:orders_loads].where(order_id: order_id).count
      "#{shipped_at.year.to_s[3, 1]}ZA01507472CDEL#{order_id}#{cnt > 1 ? 'M' : 'S'}"
    end

    def hcs_rows(load_id)
      ucr = calculate_ucr_for_load(load_id)

      query = <<~SQL
        SELECT
          CASE WHEN pallets.depot_pallet THEN
            depot_cartons.depot_carton_number::text
          ELSE
            COALESCE(legacy_barcodes.legacy_carton_number, cartons.carton_label_id::text)
          END AS carton_id,
          pallets.pallet_number AS pallet_id,
          customers.financial_account_code AS tradingpartner,
          pallet_sequences.legacy_data ->> 'extended_fg_code' AS extended_fg_code,
          -- target_market_groups.target_market_group_name AS target_market,
          fn_party_role_name(pallet_sequences.target_customer_party_role_id) AS target_market,
          COALESCE(fn_party_role_org_code(pallet_sequences.target_customer_party_role_id),
                   target_markets.target_market_name,
                   target_market_groups.target_market_group_name) AS target_market,
          loads.id AS load_no,
          farms.farm_code AS grower_id,
          -- pallets.edi_in_consignment_note_number AS intake_consignment_id,
          coalesce(pallets.legacy_data ->> 'consignment_note_number', govt_inspection_sheets.consignment_note_number) AS intake_consignment_id,
          loads.id AS exit_reference,
          -- COALESCE(pm_boms.nett_weight, pallet_sequences.nett_weight / pallet_sequences.carton_quantity, standard_product_weights.nett_weight) AS weight,
          pallet_sequences.nett_weight / pallet_sequences.carton_quantity AS weight,
          pallet_sequences.legacy_data ->> 'track_indicator_code' AS raw_material_type,
          orders.customer_order_number AS remarks,
          load_containers.container_code AS container,
          vessels.vessel_code AS vessel_name,
          voyages.voyage_code AS voyage_no,
          orders.customer_order_number AS customerpono,

          '#{ucr}' AS ucr,

          order_items.sell_by_code,

          NULL AS fg_code,

          pm_marks.description AS fg_mark_code,

          NULL AS units_per_carton,  -- pm_products_tu.items_per_unit ---
          NULL AS tu_gross_mass,     -- pm_products_tu.gross_weight_per_unit ---
          NULL AS tu_nett_mass,      -- pm_products_tu.gross_weight_per_unit - pm_products_tu.material_mass ---
          NULL AS ri_diameter_range, -- FROM _ri.std_fruit_size_count_id TO std_fruit_size_count.min & max sizes ---
          NULL AS ri_weight_range,   -- FROM _ri.std_fruit_size_count_id TO std_fruit_size_count.min & max weight ---
          NULL AS ru_description,    -- pm_products_ru.description AS ru_description
          NULL AS old_fg_code,

          LEFT(fn_party_role_name(orders.marketing_org_party_role_id), 2) AS marketing_org_code,
          grades.grade_code,
          std_fruit_size_counts.size_count_value AS standard_size_count_value,
          commodities.code AS commodity_code,
          pm_marks.packaging_marks[1] AS ri_mark_code,
          pm_marks.packaging_marks[2] AS ru_mark_code,
          pm_marks.packaging_marks[3] AS tu_mark_code,

          NULL AS unit_pack_product_code,
          NULL AS carton_pack_product_code,

          marketing_varieties.marketing_variety_code,

          NULL AS extended_fg_ru_description,
          NULL AS treatment_type_code,
          NULL AS treatment_description,
          NULL AS carton_pack_style_code,
          NULL AS carton_pack_style_description,

          basic_pack_codes.footprint_code AS basic_pack_code,

          NULL AS short_code,

          basic_pack_codes.length_mm AS length,
          basic_pack_codes.width_mm AS basic_pack_width,
          basic_pack_codes.height_mm AS basic_pack_height,

          NULL AS carton_pack_type_type_code,
          NULL AS carton_pack_type_description,
          NULL AS carton_pack_products_height,
          NULL AS carton_pack_product_type_code,
          NULL AS unit_pack_product_type_type_code,
          NULL AS unit_pack_product_type_description,
          NULL AS subtype_code,
          NULL AS unit_pack_product_subtype_description,
          NULL AS unit_pack_product_nett_mass,

          commodities.description AS commodity_description_long,
          commodities.code AS commodity_description_short,
          marketing_varieties.description AS marketing_variety_description,
          rmt_classes.rmt_class_code AS product_class_code,
          fruit_size_references.size_reference AS size_ref,

          NULL AS cosmetic_code_name,
          NULL AS treatment_code,

          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,
          customers.financial_account_code AS hansaworld,
          #{AppConst::CR_EDI.orig_account} AS account,
          farm_groups.farm_group_code AS farmsubgroup,
          farm_groups.farm_group_code AS farmgroup,
          CASE WHEN pallets.depot_pallet THEN 'Depot' ELSE 'Packed_at_Kromco' END AS depot_indicator,
          seasons.season_year AS season,

          NULL AS linetypedesc,

          pod_ports.port_code AS port_of_destination,
          cultivars.cultivar_name AS cultivar,
          incoterms.incoterm,
          COALESCE(order_items.price_per_carton, order_items.price_per_kg) AS carton_price,
          currencies.currency
        FROM loads
        LEFT JOIN load_voyages ON load_voyages.load_id = loads.id
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        LEFT JOIN voyages ON voyages.id = load_voyages.voyage_id
        LEFT JOIN vessels ON vessels.id = voyages.vessel_id
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        JOIN pallets ON pallets.load_id = loads.id
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
        LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pallet_sequences.std_fruit_size_count_id
        LEFT JOIN target_markets ON target_markets.id = pallet_sequences.target_market_id
        JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
        JOIN farms ON farms.id = pallet_sequences.farm_id
        LEFT JOIN farm_groups ON farms.farm_group_id = farm_groups.id
        JOIN grades ON grades.id = pallet_sequences.grade_id
        LEFT JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
        JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
        LEFT JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
        JOIN basic_pack_codes ON basic_pack_codes.id = pallet_sequences.basic_pack_code_id
        LEFT JOIN rmt_classes ON rmt_classes.id = pallet_sequences.rmt_class_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
        JOIN seasons ON seasons.id = pallet_sequences.season_id
        -- LEFT JOIN pm_boms ON pm_boms.id = pallet_sequences.pm_bom_id
        LEFT JOIN pm_marks ON pm_marks.id = pallet_sequences.pm_mark_id
        LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
        LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
        JOIN order_items ON order_items.id = pallet_sequences.order_item_id
        JOIN orders ON orders.id = order_items.order_id
        JOIN currencies ON currencies.id = orders.currency_id
        JOIN incoterms  ON incoterms.id = orders.incoterm_id
        JOIN customers on orders.customer_party_role_id =customers.customer_party_role_id
        LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = cultivar_groups.commodity_id
              AND standard_product_weights.standard_pack_id = pallet_sequences.standard_pack_code_id
        LEFT JOIN packing_specification_items ON packing_specification_items.id = pallet_sequences.packing_specification_item_id
        LEFT JOIN pm_products pm_products_tu ON pm_products_tu.id = packing_specification_items.tu_labour_product_id
        LEFT JOIN pm_products pm_products_ru ON pm_products_ru.id = packing_specification_items.ru_labour_product_id
        LEFT JOIN pm_products pm_products_ri ON pm_products_ri.id = packing_specification_items.ri_labour_product_id
        LEFT JOIN depot_cartons ON depot_cartons.pallet_sequence_id = pallet_sequences.id
        LEFT JOIN cartons ON cartons.pallet_sequence_id = pallet_sequences.id
        LEFT JOIN legacy_barcodes ON legacy_barcodes.carton_label_id = cartons.carton_label_id
        WHERE loads.id = ?
        ORDER BY COALESCE(depot_cartons.depot_carton_number::text, legacy_barcodes.legacy_carton_number, cartons.carton_label_id::text )
      SQL
      DB[query, load_id].all
    end

    def log_hcs_success(file_name, record_id)
      # DB[:loads].where(id: record_id).update(edi_file_name: file_name)
      log_status(:loads, record_id, 'HCS SENT', user_name: 'System', comment: file_name)
    end

    def log_hcs_fail(record_id, message)
      log_status(:loads, record_id, 'HCS SEND FAILURE', user_name: 'System', comment: message)
    end
  end
end
