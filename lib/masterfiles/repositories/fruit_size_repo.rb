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

    build_for_select :standard_product_weights,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :standard_product_weights,
                          label: :id,
                          value: :id,
                          order_by: :id

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
    crud_calls_for :standard_product_weights, name: :standard_product_weight, wrapper: StandardProductWeight
    crud_calls_for :std_fruit_size_counts, name: :std_fruit_size_count, wrapper: StdFruitSizeCount
    crud_calls_for :fruit_actual_counts_for_packs, name: :fruit_actual_counts_for_pack, wrapper: FruitActualCountsForPack
    crud_calls_for :fruit_size_references, name: :fruit_size_reference, wrapper: FruitSizeReference

    def find_standard_product_weight_flat(id)
      find_with_association(:standard_product_weights,
                            id,
                            parent_tables: [{ parent_table: :commodities,
                                              columns: %i[code],
                                              flatten_columns: { code: :commodity_code } },
                                            { parent_table: :standard_pack_codes,
                                              columns: %i[standard_pack_code],
                                              foreign_key: :standard_pack_id,
                                              flatten_columns: { standard_pack_code: :standard_pack_code } }],
                            wrapper: StandardProductWeightFlat)
    end

    def find_standard_pack_code_flat(id)
      find_with_association(:standard_pack_codes,
                            id,
                            parent_tables: [{ parent_table: :basic_pack_codes,
                                              columns: %i[basic_pack_code],
                                              flatten_columns: { basic_pack_code: :basic_pack_code } },
                                            { parent_table: :rmt_container_types,
                                              columns: %i[container_type_code],
                                              flatten_columns: { container_type_code: :container_type } },
                                            { parent_table: :rmt_container_material_types,
                                              columns: %i[container_material_type_code],
                                              flatten_columns: { container_material_type_code: :material_type } }],
                            wrapper: StandardPackCodeFlat)
    end

    def delete_basic_pack_code(id)
      dependents = DB[:fruit_actual_counts_for_packs].where(basic_pack_code_id: id).select_map(:id)
      return { error: 'This pack code is in use.' } unless dependents.empty?

      DB[:basic_pack_codes].where(id: id).delete
      { success: true }
    end

    def create_standard_pack_code(attrs)
      if AppConst::BASE_PACK_EQUALS_STD_PACK
        base_pack_id = DB[:basic_pack_codes].insert(basic_pack_code: attrs[:standard_pack_code])
        DB[:standard_pack_codes].insert(attrs.to_h.merge(basic_pack_code_id: base_pack_id))
      else
        DB[:standard_pack_codes].insert(attrs.to_h)
      end
    end

    def update_standard_pack_code(id, attrs)
      if AppConst::BASE_PACK_EQUALS_STD_PACK && attrs.to_h.key?(:standard_pack_code)
        bp_id = DB[:standard_pack_codes].where(id: id).get(:basic_pack_code_id)
        DB[:basic_pack_codes].where(id: bp_id).update(basic_pack_code: attrs[:standard_pack_code])
      end
      DB[:standard_pack_codes].where(id: id).update(attrs.to_h)
    end

    def delete_standard_pack_code(id) # rubocop:disable Metrics/AbcSize
      dependents = standard_pack_code_dependents(id)
      return failed_response('This pack code is in use.') unless dependents.empty?

      bp_id = nil
      if AppConst::BASE_PACK_EQUALS_STD_PACK
        bp_id = DB[:standard_pack_codes].where(id: id).get(:basic_pack_code_id)
        cnt = DB[:standard_pack_codes].where(basic_pack_code_id: bp_id).count
        bp_id = nil if cnt > 1
      end

      DB[:standard_pack_codes].where(id: id).delete
      DB[:basic_pack_codes].where(id: bp_id).delete if bp_id
      ok_response
    end

    def delete_std_fruit_size_count(id)
      DB[:fruit_actual_counts_for_packs].where(std_fruit_size_count_id: id).delete
      DB[:std_fruit_size_counts].where(id: id).delete
    end

    def delete_fruit_actual_counts_for_pack(id)
      DB[:fruit_actual_counts_for_packs].where(id: id).delete
    end

    def find_fruit_actual_counts_for_pack(id)
      hash = find_with_association(:fruit_actual_counts_for_packs,
                                   id,
                                   parent_tables: [{ parent_table: :std_fruit_size_counts,
                                                     columns: [:size_count_description],
                                                     flatten_columns: { size_count_description: :std_fruit_size_count } },
                                                   { parent_table: :basic_pack_codes,
                                                     columns: [:basic_pack_code],
                                                     flatten_columns: { basic_pack_code: :basic_pack_code } }],
                                   sub_tables: [{ sub_table: :fruit_size_references,
                                                  id_keys_column: :size_reference_ids,
                                                  columns: %i[id size_reference] },
                                                { sub_table: :standard_pack_codes,
                                                  id_keys_column: :standard_pack_code_ids,
                                                  columns: %i[id standard_pack_code] }],
                                   lookup_functions: [],
                                   wrapper: nil)
      return nil if hash.nil?

      hash[:standard_packs] = hash[:standard_pack_codes].map { |r| r[:standard_pack_code] }.sort.join(',')
      hash[:size_references] = hash[:fruit_size_references].map { |r| r[:size_reference] }.sort.join(',')
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

    def for_select_plant_resource_button_indicator(plant_resource_type_code)
      query = <<~SQL
        SELECT DISTINCT substring("system_resource_code"  from '..$') AS button
        FROM "system_resources"
        INNER JOIN "system_resource_types" ON ("system_resource_types"."id" = "system_resources"."system_resource_type_id")
        WHERE ("system_resource_type_code" = ?)
      SQL
      DB[query, plant_resource_type_code].select_map(:button)
    end

    def update_same_commodity_ratios(commodity_id, std_carton_nett_weight, standard_product_weight_id)
      standard_product_weight_ids = commodity_standard_product_weights(commodity_id, standard_product_weight_id)
      return if standard_product_weight_ids.empty?

      DB.execute(<<~SQL)
        UPDATE standard_product_weights SET ratio_to_standard_carton = (#{std_carton_nett_weight} / standard_carton_nett_weight)
        WHERE id IN (#{standard_product_weight_ids.join(',')});
      SQL
    end

    def commodity_standard_product_weights(commodity_id, standard_product_weight_id = nil)
      extra_conditions = standard_product_weight_id.nil? ? '' : " AND id != #{standard_product_weight_id}"
      query = <<~SQL
        SELECT id
        FROM standard_product_weights
        WHERE commodity_id = #{commodity_id} #{extra_conditions}
      SQL
      DB[query].select_map(:id)
    end

    def standard_carton_nett_weight(commodity_id)
      DB[:standard_product_weights]
        .where(commodity_id: commodity_id)
        .where(is_standard_carton: true)
        .get(:standard_carton_nett_weight)
    end

    def standard_carton_product_weights
      DB[:standard_product_weights]
        .where(is_standard_carton: true)
        .all
    end
  end
end
