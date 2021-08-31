# frozen_string_literal: true

module EdiApp
  class HcsOutRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    def hcs_rows(load_id)
      query = <<~SQL
        SELECT
          'unknown' AS carton_id,

          pallets.pallet_number AS pallet_id,

          'unknown' AS tradingpartner,

          pm_boms.system_code AS extended_fg_code,
          target_market_groups.target_market_group_name AS target_market,
          loads.id AS load_no,
          farms.farm_code AS grower_id,
          pallets.edi_in_consignment_note_number AS intake_consignment_id,
          govt_inspection_sheets.consignment_note_number AS exit_reference,

          'unknown' AS weight,
          'unknown' AS raw_material_type,

          orders.customer_order_number AS remarks,
          load_containers.container_code AS container,
          vessels.vessel_code AS vessel_name,
          voyages.voyage_code AS voyage_no,
          orders.customer_order_number AS customerpono,

          'unknown' AS ucr,

          order_items.sell_by_code,

          'unknown' AS fg_code,

          pm_marks.description AS fg_mark_code,

          'unknown' AS units_per_carton,
          'unknown' AS tu_gross_mass,
          'unknown' AS tu_nett_mass,
          'unknown' AS ri_diameter_range,
          'unknown' AS ri_weight_range,
          'unknown' AS ru_description,
          'unknown' AS old_fg_code,

          fn_party_role_name(orders.marketing_org_party_role_id) AS marketing_org_code,
          grades.grade_code,

          'unknown' AS standard_size_count_value,

          commodities.code AS commodity_code,

          'unknown' AS ri_mark_code,
          'unknown' AS ru_mark_code,
          'unknown' AS tu_mark_code,
          'unknown' AS unit_pack_product_code,
          'unknown' AS carton_pack_product_code,

          marketing_varieties.marketing_variety_code,

          'unknown' AS extended_fg_ru_description,
          'unknown' AS treatment_type_code,
          'unknown' AS treatment_description,
          'unknown' AS carton_pack_style_code,
          'unknown' AS carton_pack_style_description,

          basic_pack_codes.basic_pack_code,

          'unknown' AS short_code,

          basic_pack_codes.length_mm AS length,
          basic_pack_codes.width_mm AS basic_pack_width,
          basic_pack_codes.height_mm AS basic_pack_height,

          'unknown' AS carton_pack_type_type_code,
          'unknown' AS carton_pack_type_description,
          'unknown' AS carton_pack_products_height,
          'unknown' AS carton_pack_product_type_code,
          'unknown' AS unit_pack_product_type_type_code,
          'unknown' AS unit_pack_product_type_description,
          'unknown' AS subtype_code,
          'unknown' AS unit_pack_product_subtype_description,
          'unknown' AS unit_pack_product_nett_mass,

          commodities.description AS commodity_description_long,
          commodities.code AS commodity_description_short,
          marketing_varieties.description AS marketing_variety_description,
          rmt_classes.rmt_class_code AS product_class_code,
          fruit_size_references.size_reference AS size_ref,

          'unknown' AS cosmetic_code_name,
          'unknown' AS treatment_code,
          fruit_actual_counts_for_packs.actual_count_for_pack AS actual_count,

          'unknown' AS hansaworld,
          'unknown' AS account,

          farm_groups.farm_group_code AS farmsubgroup,
          farm_groups.farm_group_code AS farmgroup,
          CASE WHEN pallets.depot_pallet THEN 'Depot' ELSE 'Packed_at_Kromco' END AS depot_indicator,
          seasons.season_code AS season,
          'unknown' AS linetypedesc,
          pod_ports.port_code AS port_of_destination,
          cultivars.cultivar_name AS cultivar,
          incoterms.incoterm,
          currencies.currency,
          COALESCE(order_items.price_per_carton, order_items.price_per_kg) AS carton_price
        FROM loads
        LEFT JOIN load_voyages ON load_voyages.load_id = loads.id
        LEFT JOIN voyage_ports pod_voyage_ports ON pod_voyage_ports.id = loads.pod_voyage_port_id
        LEFT JOIN ports pod_ports ON pod_ports.id = pod_voyage_ports.port_id
        LEFT JOIN voyages ON voyages.id = load_voyages.voyage_id
        LEFT JOIN vessels ON vessels.id = voyages.vessel_id
        LEFT JOIN load_containers ON load_containers.load_id = loads.id
        JOIN pallets ON pallets.load_id = loads.id
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
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
        LEFT JOIN pm_boms ON pm_boms.id = pallet_sequences.pm_bom_id
        LEFT JOIN pm_marks ON pm_marks.id = pallet_sequences.pm_mark_id
        LEFT JOIN govt_inspection_pallets ON govt_inspection_pallets.id = pallets.last_govt_inspection_pallet_id
        LEFT JOIN govt_inspection_sheets ON govt_inspection_sheets.id = govt_inspection_pallets.govt_inspection_sheet_id
        JOIN order_items ON order_items.id = pallet_sequences.order_item_id
        JOIN orders ON orders.id = order_items.order_id
        JOIN currencies ON currencies.id = orders.currency_id
        JOIN incoterms  ON incoterms.id = orders.incoterm_id
        WHERE loads.id = ?
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
