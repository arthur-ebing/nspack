# frozen_string_literal: true

module EdiApp
  class NsgtinInRepo < BaseRepo
    # All GTIN data without lookup
    # def gtins_without_masterfiles
    #   query = <<~SQL
    #     SELECT
    #     org_code, commodity_code, marketing_variety_code, standard_pack_code, grade_code, mark_code, size_count_code, inventory_code
    #     FROM gtins
    #     WHERE commodity_id IS NULL
    #     OR marketing_variety_id IS NULL
    #     OR marketing_org_party_role_id IS NULL
    #     OR standard_pack_code_id IS NULL
    #     OR mark_id IS NULL
    #     OR grade_id IS NULL
    #     OR inventory_code_id IS NULL
    #     OR (fruit_actual_counts_for_pack_id IS NULL AND OR fruit_size_reference_id IS NULL)
    #   SQL
    #   DB[query].all
    # end

    # def missing_gtin_commodities
    #   DB[:gtins].where(commodity_id: nil).distinct.select_map(:commodity_code)
    # end
    #
    # def update_gtin_commodities(code, id)
    #   DB[:gtins].where(commodity_code: code).update(commodity_id: id)
    # end

    def missing_gtin_marks
      DB[:gtins].where(mark_id: nil).distinct.select_map(:mark_code)
    end

    def update_gtin_marks(code, id)
      DB[:gtins].where(mark_code: code).update(mark_id: id)
    end

    def missing_gtin_grades
      DB[:gtins].where(grade_id: nil).distinct.select_map(:grade_code)
    end

    def update_gtin_grades(code, id)
      DB[:gtins].where(grade_code: code).update(grade_id: id)
    end

    def missing_gtin_inventory_codes
      DB[:gtins].where(inventory_code_id: nil).exclude(inventory_code: nil).distinct.select_map(:inventory_code)
    end

    def update_gtin_inventory_codes(code, id)
      DB[:gtins].where(inventory_code: code).update(inventory_code_id: id)
    end

    def missing_gtin_standard_pack_codes
      DB[:gtins].where(standard_pack_code_id: nil).distinct.select_map(:standard_pack_code)
    end

    def update_gtin_standard_pack_codes(code, id)
      DB[:gtins].where(standard_pack_code: code).update(standard_pack_code_id: id)
    end

    def missing_gtin_marketing_varieties
      DB[:gtins].where(marketing_variety_id: nil).distinct.select_map(%i[commodity_code marketing_variety_code])
    end

    def update_gtin_marketing_varieties(commodity_code, code, id)
      DB[:gtins].where(commodity_code: commodity_code, marketing_variety_code: code).update(marketing_variety_id: id)
    end

    def missing_gtin_marketing_orgs
      DB[:gtins].where(marketing_org_party_role_id: nil).distinct.select_map(:org_code)
    end

    def update_gtin_marketing_orgs(code, id)
      DB[:gtins].where(org_code: code).update(marketing_org_party_role_id: id)
    end

    # def missing_gtin_size_count_codes
    #   DB[:gtins].where(fruit_actual_counts_for_pack_id: nil, fruit_size_reference_id: nil).distinct.select_map(%i[commodity_code standard_pack_code size_count_code])
    # end

    def missing_gtin_size_refs
      DB[:gtins].where(fruit_actual_counts_for_pack_id: nil, fruit_size_reference_id: nil, size_count_code: /[^0-9]/).distinct.select_map(:size_count_code)
    end

    def missing_gtin_actual_counts
      DB[:gtins]
        .where(fruit_actual_counts_for_pack_id: nil, fruit_size_reference_id: nil, size_count_code: /^[0-9]+$/)
        .distinct
        .select_map(%i[commodity_code standard_pack_code size_count_code])
    end

    def update_gtin_fruit_actual_counts_for_packs(commodity_code, standard_pack_code, code, id)
      DB[:gtins].where(commodity_code: commodity_code,
                       standard_pack_code: standard_pack_code,
                       size_count_code: code).update(fruit_actual_counts_for_pack_id: id)
    end

    def update_gtin_fruit_size_references(code, id)
      DB[:gtins].where(size_count_code: code).update(fruit_size_reference_id: id)
    end
    # commodity_id,
    # marketing_variety_id,
    # marketing_org_party_role_id,
    # standard_pack_code_id,
    # mark_id,
    # grade_id,
    # inventory_code_id,
    # fruit_actual_counts_for_pack_id,
    # fruit_size_reference_id

    def find_basic_pack_id(standard_pack_code_id)
      DB[:basic_packs_standard_packs].where(standard_pack_id: standard_pack_code_id).get(:basic_pack_id)
    end

    def fruit_actual_counts_for_pack_via_std_commodity(basic_pack_code_id, size_count, commodity_id)
      DB[:fruit_actual_counts_for_packs]
        .join(:std_fruit_size_counts, id: :std_fruit_size_count_id)
        .where(basic_pack_code_id: basic_pack_code_id,
               actual_count_for_pack: size_count,
               commodity_id: commodity_id)
        .get(Sequel[:fruit_actual_counts_for_packs][:id])
    end
  end
end
