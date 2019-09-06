# frozen_string_literal: true

module MasterfilesApp
  class FruitSizeRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :basic_pack_codes,
                     label: :basic_pack_code,
                     value: :id,
                     order_by: :basic_pack_code
    build_inactive_select :basic_pack_codes,
                          label: :basic_pack_code,
                          value: :id,
                          order_by: :basic_pack_code

    build_for_select :standard_pack_codes,
                     label: :standard_pack_code,
                     value: :id,
                     order_by: :standard_pack_code
    build_inactive_select :standard_pack_codes,
                          label: :standard_pack_code,
                          value: :id,
                          order_by: :standard_pack_code

    build_for_select :std_fruit_size_counts,
                     label: :size_count_value,
                     value: :id,
                     order_by: :size_count_value
    build_inactive_select :std_fruit_size_counts,
                          label: :size_count_value,
                          value: :id,
                          order_by: :size_count_value

    build_for_select :fruit_actual_counts_for_packs,
                     label: :actual_count_for_pack,
                     value: :id,
                     order_by: :actual_count_for_pack
    build_inactive_select :fruit_actual_counts_for_packs,
                          label: :actual_count_for_pack,
                          value: :id,
                          order_by: :actual_count_for_pack

    build_for_select :fruit_size_references,
                     label: :size_reference,
                     value: :id,
                     order_by: :size_reference
    build_inactive_select :fruit_size_references,
                          label: :size_reference,
                          value: :id,
                          order_by: :size_reference

    crud_calls_for :basic_pack_codes, name: :basic_pack_code, wrapper: BasicPackCode
    crud_calls_for :standard_pack_codes, name: :standard_pack_code, wrapper: StandardPackCode
    crud_calls_for :std_fruit_size_counts, name: :std_fruit_size_count, wrapper: StdFruitSizeCount
    crud_calls_for :fruit_actual_counts_for_packs, name: :fruit_actual_counts_for_pack, wrapper: FruitActualCountsForPack
    crud_calls_for :fruit_size_references, name: :fruit_size_reference, wrapper: FruitSizeReference

    def delete_basic_pack_code(id)
      dependents = DB[:fruit_actual_counts_for_packs].where(basic_pack_code_id: id).select_map(:id)
      return { error: 'This pack code is in use.' } unless dependents.empty?

      DB[:basic_pack_codes].where(id: id).delete
      { success: true }
    end

    def delete_standard_pack_code(id)
      dependents = standard_pack_code_dependents(id)
      return { error: 'This pack code is in use.' } unless dependents.empty?

      DB[:standard_pack_codes].where(id: id).delete
      { success: true }
    end

    def delete_std_fruit_size_count(id)
      DB[:fruit_actual_counts_for_packs].where(std_fruit_size_count_id: id).delete
      DB[:std_fruit_size_counts].where(id: id).delete
    end

    def delete_fruit_actual_counts_for_pack(id)
      DB[:fruit_actual_counts_for_packs].where(id: id).delete
    end

    def find_fruit_actual_counts_for_pack(id)
      hash = DB["SELECT fruit_actual_counts_for_packs.*, std_fruit_size_counts.size_count_description AS std_fruit_size_count,
                 basic_pack_codes.basic_pack_code, spc.standard_pack_codes, fsr.size_references
                 FROM fruit_actual_counts_for_packs
                 JOIN std_fruit_size_counts ON std_fruit_size_counts.id = fruit_actual_counts_for_packs.std_fruit_size_count_id
                 JOIN basic_pack_codes ON basic_pack_codes.id = fruit_actual_counts_for_packs.basic_pack_code_id
                 JOIN (SELECT fruit_actual_counts_for_packs.id AS fruit_actual_counts_for_packs_id,string_agg(standard_pack_codes.standard_pack_code, ', ') AS standard_pack_codes
                       FROM standard_pack_codes
                       JOIN fruit_actual_counts_for_packs ON standard_pack_codes.id = ANY (fruit_actual_counts_for_packs.standard_pack_code_ids)
                       GROUP BY fruit_actual_counts_for_packs.id) spc ON spc.fruit_actual_counts_for_packs_id = fruit_actual_counts_for_packs.id
                 JOIN (SELECT fruit_actual_counts_for_packs.id AS fruit_actual_counts_for_packs_id,string_agg(fruit_size_references.size_reference, ', ') AS size_references
                       FROM fruit_size_references
                       JOIN fruit_actual_counts_for_packs ON fruit_size_references.id = ANY (fruit_actual_counts_for_packs.size_reference_ids)
                       GROUP BY fruit_actual_counts_for_packs.id) fsr ON fsr.fruit_actual_counts_for_packs_id = fruit_actual_counts_for_packs.id
                 WHERE fruit_actual_counts_for_packs.id = ?", id].first
      return nil if hash.nil?

      FruitActualCountsForPack.new(hash)
    end

    def standard_pack_codes(id)
      query = <<~SQL
        SELECT standard_pack_codes.standard_pack_code
        FROM standard_pack_codes
        JOIN fruit_actual_counts_for_packs ON standard_pack_codes.id = ANY (fruit_actual_counts_for_packs.standard_pack_code_ids)
        WHERE fruit_actual_counts_for_packs.id = #{id}
      SQL
      DB[query].order(:standard_pack_code).select_map(:standard_pack_code)
    end

    def size_references(id)
      query = <<~SQL
        SELECT fruit_size_references.size_reference
        FROM fruit_size_references
        JOIN fruit_actual_counts_for_packs ON fruit_size_references.id = ANY (fruit_actual_counts_for_packs.size_reference_ids)
        WHERE fruit_actual_counts_for_packs.id = #{id}
      SQL
      DB[query].order(:size_reference).select_map(:size_reference)
    end

    def standard_pack_code_dependents(id)
      query = <<~SQL
        SELECT id
        FROM fruit_actual_counts_for_packs
        WHERE #{id} = ANY (standard_pack_code_ids)
      SQL
      DB[query].select_map(:id)
    end
  end
end
