# frozen_string_literal: true

module MasterfilesApp
  class FruitSizeRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_inactive_select :basic_pack_codes,
                          alias: :basic_packs,
                          label: :basic_pack_code,
                          value: :id,
                          order_by: :basic_pack_code

    build_inactive_select :standard_pack_codes,
                          alias: :standard_packs,
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
    crud_calls_for :std_fruit_size_counts, name: :std_fruit_size_count, exclude: %i[delete]

    build_for_select :standard_product_weights,
                     label: :id,
                     value: :id,
                     order_by: :id
    build_inactive_select :standard_product_weights,
                          label: :id,
                          value: :id,
                          order_by: :id
    crud_calls_for :standard_product_weights, name: :standard_product_weight, wrapper: StandardProductWeight

    build_for_select :fruit_size_references,
                     label: :size_reference,
                     value: :id,
                     order_by: :size_reference
    build_inactive_select :fruit_size_references,
                          label: :size_reference,
                          value: :id,
                          order_by: :size_reference
    crud_calls_for :fruit_size_references, name: :fruit_size_reference, wrapper: FruitSizeReference

    build_for_select :fruit_actual_counts_for_packs,
                     label: :actual_count_for_pack,
                     value: :id,
                     order_by: :actual_count_for_pack
    build_inactive_select :fruit_actual_counts_for_packs,
                          label: :actual_count_for_pack,
                          value: :id,
                          order_by: :actual_count_for_pack
    crud_calls_for :fruit_actual_counts_for_packs, name: :fruit_actual_counts_for_pack

    def for_select_basic_packs(where: {}, exclude: {}, active: true)
      DB[:basic_pack_codes]
        .left_join(:basic_packs_standard_packs, basic_pack_id: :id)
        .where(active: active)
        .where(where)
        .exclude(exclude)
        .order(:basic_pack_code)
        .distinct
        .select_map(%i[basic_pack_code id])
    end

    def find_basic_pack(id)
      hash = find_with_association(:basic_pack_codes, id)
      return nil if hash.nil?

      hash[:standard_pack_ids] = select_values(:basic_packs_standard_packs, :standard_pack_id, basic_pack_id: id)
      hash[:standard_pack_codes] = select_values(:standard_pack_codes, :standard_pack_code, id: hash[:standard_pack_ids])
      BasicPack.new(hash)
    end

    def create_basic_pack(res)
      attrs = res.to_h
      standard_pack_ids = attrs.delete(:standard_pack_ids) || []
      basic_pack_id = create(:basic_pack_codes, attrs)
      standard_pack_ids.each do |standard_pack_id|
        DB[:basic_packs_standard_packs].insert(basic_pack_id: basic_pack_id, standard_pack_id: standard_pack_id)
      end
      return basic_pack_id unless AppConst::CR_MF.basic_pack_equals_standard_pack?

      standard_pack_id = create(:standard_pack_codes, standard_pack_code: attrs[:basic_pack_code], material_mass: 0)
      create(:basic_packs_standard_packs, standard_pack_id: standard_pack_id, basic_pack_id: basic_pack_id)
      basic_pack_id
    end

    def update_basic_pack(id, res)
      attrs = res.to_h
      new_standard_pack_ids = attrs.delete(:standard_pack_ids) || []
      old_standard_pack_ids = select_values(:basic_packs_standard_packs, :standard_pack_id, basic_pack_id: id)

      (new_standard_pack_ids - old_standard_pack_ids).each do |standard_pack_id|
        DB[:basic_packs_standard_packs].insert(basic_pack_id: id, standard_pack_id: standard_pack_id)
      end
      (old_standard_pack_ids - new_standard_pack_ids).each do |standard_pack_id|
        DB[:basic_packs_standard_packs].where(basic_pack_id: id, standard_pack_id: standard_pack_id).delete
      end

      update(:basic_pack_codes, id, attrs)
    end

    def delete_basic_pack(id)
      standard_pack_ids = select_values(:basic_packs_standard_packs, :standard_pack_id, basic_pack_id: id)
      DB[:basic_packs_standard_packs].where(basic_pack_id: id).delete
      delete(:standard_pack_codes, standard_pack_ids.first) if AppConst::CR_MF.basic_pack_equals_standard_pack?
      delete(:basic_pack_codes, id)
    end

    def for_select_standard_packs(where: {}, exclude: {}, active: true)
      DB[:standard_pack_codes]
        .left_join(:basic_packs_standard_packs, standard_pack_id: :id)
        .where(active: active)
        .where(where)
        .exclude(exclude)
        .order(:standard_pack_code)
        .distinct
        .select_map(%i[standard_pack_code id])
    end

    def find_standard_pack(id)
      hash = find_with_association(:standard_pack_codes, id,
                                   parent_tables: [{ parent_table: :rmt_container_types,
                                                     columns: %i[container_type_code],
                                                     flatten_columns: { container_type_code: :container_type } },
                                                   { parent_table: :rmt_container_material_types,
                                                     columns: %i[container_material_type_code],
                                                     flatten_columns: { container_material_type_code: :material_type } }])
      return nil if hash.nil?

      hash[:basic_pack_ids] = select_values(:basic_packs_standard_packs, :basic_pack_id, standard_pack_id: id)
      hash[:basic_pack_codes] = select_values(:basic_pack_codes, :basic_pack_code, id: hash[:basic_pack_ids])
      StandardPack.new(hash)
    end

    def create_standard_pack(res)
      attrs = res.to_h
      basic_pack_ids = attrs.delete(:basic_pack_ids) || []
      standard_pack_id = create(:standard_pack_codes, attrs)
      basic_pack_ids.each do |basic_pack_id|
        DB[:basic_packs_standard_packs].insert(basic_pack_id: basic_pack_id, standard_pack_id: standard_pack_id)
      end
      return standard_pack_id unless AppConst::CR_MF.basic_pack_equals_standard_pack?

      basic_pack_id = create(:basic_pack_codes, basic_pack_code: attrs[:standard_pack_code])
      create(:basic_packs_standard_packs, standard_pack_id: standard_pack_id, basic_pack_id: basic_pack_id)
      standard_pack_id
    end

    def update_standard_pack(id, res) # rubocop:disable Metrics/AbcSize
      attrs = res.to_h
      new_basic_pack_ids = attrs.delete(:basic_pack_ids) || []
      old_basic_pack_ids = select_values(:basic_packs_standard_packs, :basic_pack_id, standard_pack_id: id)

      (new_basic_pack_ids - old_basic_pack_ids).each do |basic_pack_id|
        DB[:basic_packs_standard_packs].insert(basic_pack_id: basic_pack_id, standard_pack_id: id)
      end
      (old_basic_pack_ids - new_basic_pack_ids).each do |basic_pack_id|
        DB[:basic_packs_standard_packs].where(basic_pack_id: basic_pack_id, standard_pack_id: id).delete
      end

      if AppConst::CR_MF.basic_pack_equals_standard_pack? && attrs.key?(:standard_pack_code)
        basic_pack_id = DB[:basic_packs_standard_packs].where(standard_pack_id: id).get(:basic_pack_id)
        update(:basic_pack_codes, basic_pack_id, basic_pack_code: attrs[:standard_pack_code])
      end

      update(:standard_pack_codes, id, attrs)
    end

    def delete_standard_pack(id)
      basic_pack_ids = select_values(:basic_packs_standard_packs, :basic_pack_id, standard_pack_id: id)
      DB[:basic_packs_standard_packs].where(standard_pack_id: id).delete
      delete(:basic_pack_codes, basic_pack_ids.first) if AppConst::CR_MF.basic_pack_equals_standard_pack?
      delete(:standard_pack_codes, id)
    end

    def find_standard_product_weight_flat(id)
      find_with_association(:standard_product_weights, id,
                            parent_tables: [{ parent_table: :commodities,
                                              columns: %i[code],
                                              flatten_columns: { code: :commodity_code } },
                                            { parent_table: :standard_pack_codes,
                                              columns: %i[standard_pack_code],
                                              foreign_key: :standard_pack_id,
                                              flatten_columns: { standard_pack_code: :standard_pack_code } }],
                            wrapper: StandardProductWeightFlat)
    end

    def find_std_fruit_size_count(id)
      query = <<~SQL
        SELECT
          std_fruit_size_counts.*,
          commodities.code AS commodity_code,
          commodities.code || std_fruit_size_counts.size_count_value AS product_code,
          commodities.code || uoms.uom_code || std_fruit_size_counts.size_count_value AS system_code,
          commodities.code || std_fruit_size_counts.size_count_value AS extended_description
        FROM std_fruit_size_counts
        JOIN commodities ON commodities.id = std_fruit_size_counts.commodity_id
        JOIN uoms ON uoms.id = std_fruit_size_counts.uom_id
        WHERE std_fruit_size_counts.id = ?
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      StdFruitSizeCount.new(hash)
    end

    def delete_std_fruit_size_count(id)
      DB[:fruit_actual_counts_for_packs].where(std_fruit_size_count_id: id).delete
      DB[:std_fruit_size_counts].where(id: id).delete
    end

    def find_fruit_actual_counts_for_pack(id) # rubocop:disable Metrics/AbcSize
      hash = find_with_association(:fruit_actual_counts_for_packs, id,
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
                                   lookup_functions: [])
      return nil if hash.nil?

      hash[:standard_packs] = hash[:standard_pack_codes].map { |r| r[:standard_pack_code] }.sort.join(',')
      hash[:size_references] = hash[:fruit_size_references].map { |r| r[:size_reference] }.sort.join(',')
      hash[:standard_pack_code_ids] = hash[:standard_pack_code_ids].to_a
      hash[:size_reference_ids] = hash[:size_reference_ids].to_a

      FruitActualCountsForPack.new(hash)
    end

    def list_standard_pack_codes(id)
      query = <<~SQL
        SELECT standard_pack_codes.standard_pack_code
        FROM standard_pack_codes
        JOIN fruit_actual_counts_for_packs ON standard_pack_codes.id = ANY (fruit_actual_counts_for_packs.standard_pack_code_ids)
        WHERE fruit_actual_counts_for_packs.id = #{id}
      SQL
      DB[query].order(:standard_pack_code).select_map(:standard_pack_code)
    end

    def list_size_references(id)
      query = <<~SQL
        SELECT fruit_size_references.size_reference
        FROM fruit_size_references
        JOIN fruit_actual_counts_for_packs ON fruit_size_references.id = ANY (fruit_actual_counts_for_packs.size_reference_ids)
        WHERE fruit_actual_counts_for_packs.id = #{id}
      SQL
      DB[query].order(:size_reference).select_map(:size_reference)
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

    def get_standard_carton_nett_weight(commodity_id)
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
