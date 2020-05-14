# frozen_string_literal: true

module EdiApp
  class UistkOutRepo < BaseRepo
    def uistk_rows(party_role_id)
      query = <<~SQL
        SELECT
          pallet_sequences.pallet_number,
          pallet_sequences.pallet_sequence_number,
          pallet_sequences.production_run_id,
          (SELECT t.treatment_code
            FROM treatments t
            JOIN treatment_types y ON y.id = t.treatment_type_id
            WHERE t.id = ANY (pallet_sequences.treatment_ids)
            AND y.treatment_type_code = 'CHEMICAL_CONTENT' LIMIT 1) AS chemical_content
        FROM pallet_sequences
        JOIN pallets ON pallets.id = pallet_sequences.pallet_id
        WHERE pallets.in_stock
          AND pallet_sequences.marketing_org_party_role_id = ?
      SQL
      DB[query, party_role_id].all
    end
  end
end
