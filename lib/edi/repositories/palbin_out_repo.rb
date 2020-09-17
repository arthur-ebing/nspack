# frozen_string_literal: true

module EdiApp
  class PalbinOutRepo < EdiOutRepo
    def palbin_details(load_id)
      query = <<~SQL
        SELECT
            loads.id AS load_id,
            loads.shipped_at,
            depots.depot_code destination,
            '#{AppConst::INSTALL_LOCATION}' AS depot,
            pallets.pallet_number AS sscc,
            farms.farm_code AS farm,
            pucs.puc_code AS puc,
            orchards.orchard_code AS orchard,
            commodities.code AS commodity,
            cultivars.cultivar_name AS cultivar,
            grades.grade_code AS grade,
            standard_pack_codes.standard_pack_code AS pack,
            fruit_size_references.size_reference,
            ROUND(pallets.gross_weight, 2)::text AS gross_weight,
            ROUND(pallet_sequences.nett_weight, 2)::text AS nett_weight

        FROM loads
        JOIN depots ON depots.id = loads.depot_id
        JOIN pallets ON pallets.load_id = loads.id AND NOT scrapped
        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id AND NOT scrapped
        JOIN farms ON farms.id = pallet_sequences.farm_id
        JOIN pucs ON pucs.id = pallet_sequences.puc_id
        JOIN orchards ON orchards.id = pallet_sequences.orchard_id
        JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
        JOIN cultivars ON cultivars.id = pallet_sequences.cultivar_id
        JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        JOIN grades ON grades.id = pallet_sequences.grade_id
        JOIN standard_pack_codes ON standard_pack_codes.id = pallet_sequences.standard_pack_code_id
        JOIN fruit_size_references ON fruit_size_references.id = pallet_sequences.fruit_size_reference_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = pallet_sequences.fruit_actual_counts_for_pack_id

        WHERE loads.rmt_load
        AND loads.id = ?
        ORDER BY pallets.pallet_number
      SQL
      DB[query, load_id].all
    end
  end
end
