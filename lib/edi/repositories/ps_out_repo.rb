# frozen_string_literal: true

module EdiApp
  class PsOutRepo < BaseRepo
    def ps_rows(marketing_org)
      query = <<~SQL
        SELECT
          substring(pallet_sequences.pallet_number from '.........$') AS pallet_id,
          pallet_sequences.pallet_sequence_number AS sequence_number,
          govt_inspection_sheets.id AS consignment_number,
          marketing_org.short_description AS organisation,
          substring(commodity_groups.code FROM '..') AS commodity_group,
          commodities.code AS commodity,
          marketing_varieties.marketing_variety_code AS variety,
          standard_pack_codes.standard_pack_code AS pack,
          grades.grade_code AS grade,
          COALESCE(fruit_size_references.size_reference, fruit_actual_counts_for_packs.actual_count_for_pack::text) AS size_count,
          marks.mark_code AS mark,
          inventory_codes.inventory_code,
          pallet_sequences.pick_ref AS picking_reference,
          pallet_sequences.product_chars AS product_characteristic_code,
          target_market_groups.target_market_group_name AS target_market,
          pucs.puc_code AS farm,
          pallet_sequences.carton_quantity,
          pallets.carton_quantity AS pallet_quantity,
          CASE WHEN (SELECT count(*) FROM pallet_sequences m WHERE m.pallet_id = pallet_sequences.pallet_id AND NOT scrapped) > 1 THEN 'Y' ELSE 'N' END AS mixed_indicator,
          COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at) AS intake_date,
          pallets.govt_first_inspection_at AS original_intake,
          pallets.first_cold_storage_at AS cold_date,
          'CE' AS stock_pool,                                                                            -- IS THIS UM-specific....
          COALESCE(pallets.stock_created_at, pallets.created_at) AS transaction_date,
          COALESCE(pallets.stock_created_at, pallets.created_at) AS transaction_time,
          pallet_bases.edi_out_pallet_base AS pallet_base_type,
          pallets.pallet_number AS sscc,
          govt_inspection_sheets.id AS waybill_no,
          pallet_sequences.sell_by_code AS sellbycode,
          pallets.pallet_number AS combo_sscc,
          COALESCE(pallets.govt_reinspection_at, pallets.govt_first_inspection_at) AS inspec_date,
          pallets.govt_first_inspection_at AS orig_inspec_date,
          pallets.phc AS packh_code,
          orchards.orchard_code AS orchard,
          pallets.gross_weight AS pallet_gross_mass,
          pallets.gross_weight_measured_at AS weighing_date,
          pallets.gross_weight_measured_at AS weighing_time,
          pallets.nett_weight AS mass
        FROM pallet_sequences
        JOIN pallets ON pallets.id = pallet_sequences.pallet_id
        JOIN party_roles mpr ON mpr.id = pallet_sequences.marketing_org_party_role_id
        JOIN organizations marketing_org ON marketing_org.party_id = mpr.party_id
        LEFT OUTER JOIN govt_inspection_sheets ON govt_inspection_sheets.id = pallets.last_govt_inspection_pallet_id
        JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
        JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        JOIN commodity_groups ON commodity_groups.id = commodities.commodity_group_id
        JOIN marketing_varieties ON marketing_varieties.id = pallet_sequences.marketing_variety_id
        JOIN marks ON marks.id = pallet_sequences.mark_id
        JOIN inventory_codes ON inventory_codes.id = pallet_sequences.inventory_code_id
        JOIN target_market_groups ON target_market_groups.id = pallet_sequences.packed_tm_group_id
        JOIN grades ON grades.id = pallet_sequences.grade_id
        JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id
        JOIN pucs ON pucs.id = pallet_sequences.puc_id
        JOIN orchards ON orchards.id = pallet_sequences.orchard_id
        LEFT JOIN pallet_formats ON pallet_formats.id = pallets.pallet_format_id
        LEFT JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
        WHERE pallets.in_stock
          AND marketing_org.short_description = ?
      SQL
      DB[query, marketing_org].all
    end

    def ps_rows_vw(marketing_org)
      DB[:vw_pallet_sequence_flat].where(in_stock: true, marketing_org: marketing_org).order(:pallet_number, :pallet_sequence_number).all
    end
  end
end
