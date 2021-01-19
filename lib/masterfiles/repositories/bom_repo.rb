# frozen_string_literal: true

module MasterfilesApp
  class BomRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :pm_types, label: :pm_type_code, value: :id, order_by: :pm_type_code
    build_inactive_select :pm_types, label: :pm_type_code, value: :id, order_by: :pm_type_code
    crud_calls_for :pm_types, name: :pm_type, wrapper: PmType

    build_for_select :pm_subtypes, label: :subtype_code, value: :id, order_by: :subtype_code
    build_inactive_select :pm_subtypes, label: :subtype_code, value: :id, order_by: :subtype_code
    crud_calls_for :pm_subtypes, name: :pm_subtype, wrapper: PmSubtype

    build_for_select :pm_products, label: :product_code, value: :id, order_by: :product_code
    build_inactive_select :pm_products, label: :product_code, value: :id, order_by: :product_code
    crud_calls_for :pm_products, name: :pm_product, wrapper: PmProduct

    build_for_select :pm_boms, label: :bom_code, value: :id, order_by: :bom_code
    build_inactive_select :pm_boms, label: :bom_code, value: :id, order_by: :bom_code
    crud_calls_for :pm_boms, name: :pm_bom, wrapper: PmBom

    build_for_select :pm_boms_products, label: :quantity, value: :id, order_by: :quantity
    build_inactive_select :pm_boms_products, label: :quantity, value: :id, order_by: :quantity
    crud_calls_for :pm_boms_products, name: :pm_boms_product, wrapper: PmBomsProduct

    build_for_select :pm_composition_levels, label: :description, value: :id, order_by: :description
    build_inactive_select :pm_composition_levels, label: :description, value: :id, order_by: :description
    crud_calls_for :pm_composition_levels, name: :pm_composition_level, wrapper: PmCompositionLevel

    build_for_select :pm_marks, label: :description, value: :id, order_by: :description
    build_inactive_select :pm_marks, label: :description, value: :id, order_by: :description
    crud_calls_for :pm_marks, name: :pm_mark, wrapper: PmMark

    def pm_subtypes(pm_subtype_ids)
      DB[:pm_subtypes]
        .join(:pm_types, id: :pm_type_id)
        .where(Sequel[:pm_subtypes][:id] => pm_subtype_ids)
        .order(:pm_type_code)
        .select(
          :pm_type_code,
          :subtype_code
        ).map { |r| ["#{r[:pm_type_code]} - #{r[:subtype_code]}"] }
    end

    def find_pm_subtype_products(id)
      DB[:pm_products]
        .join(:pm_subtypes, id: :pm_subtype_id)
        .where(pm_subtype_id: id)
        .order(:product_code)
        .select_map(:product_code)
    end

    def for_select_pm_uoms(uom_type)
      DB[:uoms]
        .where(uom_type_id: DB[:uom_types].where(code: uom_type).select(:id))
        .select_map(%i[uom_code id])
    end

    def find_pm_type(id)
      hash = find_with_association(:pm_types,
                                   id,
                                   parent_tables: [{ parent_table: :pm_composition_levels,
                                                     columns: [:description],
                                                     flatten_columns: { description: :composition_level } }])
      return nil if hash.nil?

      PmType.new(hash)
    end

    def find_pm_subtype(id)
      hash = find_with_association(:pm_subtypes,
                                   id,
                                   parent_tables: [{ parent_table: :pm_types,
                                                     columns: [:pm_type_code],
                                                     flatten_columns: { pm_type_code: :pm_type_code } }])
      return nil if hash.nil?

      PmSubtype.new(hash)
    end

    def find_pm_product(id)
      query = <<~SQL
        SELECT
            pm_products.*,
            pm_subtypes.subtype_code,
            pm_types.pm_type_code,
            basic_pack_codes.basic_pack_code,
            pm_composition_levels.composition_level
        FROM pm_products
        LEFT JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
        LEFT JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
        LEFT JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
        LEFT JOIN basic_pack_codes ON basic_pack_codes.id = pm_products.basic_pack_id
        WHERE pm_products.id = ?
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      PmProduct.new(hash)
    end

    def find_pm_boms_product(id)
      hash = find_with_association(:pm_boms_products,
                                   id,
                                   parent_tables: [{ parent_table: :pm_products,
                                                     columns: [:product_code],
                                                     flatten_columns: { product_code: :product_code } },
                                                   { parent_table: :pm_boms,
                                                     columns: [:bom_code],
                                                     flatten_columns: { bom_code: :bom_code } },
                                                   { parent_table: :uoms,
                                                     columns: [:uom_code],
                                                     foreign_key: :uom_id,
                                                     flatten_columns: { uom_code: :uom_code } }])
      return nil if hash.nil?

      PmBomsProduct.new(hash)
    end

    def find_pm_mark(id)
      hash = find_with_association(:pm_marks,
                                   id,
                                   parent_tables: [{ parent_table: :marks,
                                                     columns: [:mark_code],
                                                     flatten_columns: { mark_code: :mark_code } }])
      return nil if hash.nil?

      PmMarkFlat.new(hash)
    end

    def for_select_setup_pm_boms(commodity_id, std_fruit_size_count_id, basic_pack_code_id)
      return [] if commodity_id.nil_or_empty? || std_fruit_size_count_id.nil_or_empty? || basic_pack_code_id.nil_or_empty?

      commodity_code = DB[:commodities].where(id: commodity_id).get(:code)
      size_count = DB[:std_fruit_size_counts].where(id: std_fruit_size_count_id).get(:size_count_value)

      DB["SELECT DISTINCT pm_boms.id, pm_boms.bom_code
          FROM pm_boms_products
          JOIN pm_boms ON pm_boms.id = pm_boms_products.pm_bom_id
          JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
          JOIN ( SELECT pp.id, pp.basic_pack_id
					       FROM pm_products pp
                 JOIN pm_subtypes ON pm_subtypes.id = pp.pm_subtype_id
                 JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
                 JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
                 ORDER BY pm_composition_levels.composition_level ASC LIMIT 1) cpp ON cpp.id = pm_boms_products.pm_product_id
          WHERE pm_boms.bom_code LIKE '%#{commodity_code}_#{size_count}'
          AND cpp.basic_pack_id = #{basic_pack_code_id}"]
        .map { |r| [r[:bom_code], r[:id]] }
    end

    def pm_bom_products(id)
      query = <<~SQL
        SELECT product_code,pm_type_code, subtype_code, uom_code, quantity, pm_composition_levels.composition_level
        FROM pm_products
        JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
        JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
        JOIN pm_boms_products ON pm_products.id = pm_boms_products.pm_product_id
        JOIN uoms ON uoms.id = pm_boms_products.uom_id
        JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
        WHERE pm_bom_id = #{id}
        ORDER BY pm_composition_levels.composition_level
      SQL
      DB[query].all unless id.nil?
    end

    def find_pm_products_by_pm_type(pm_type)
      DB["select p.id, p.product_code
          from pm_products p
          join pm_subtypes s on s.id=p.pm_subtype_id
          join pm_types t on t.id=s.pm_type_id
          where t.pm_type_code = '#{pm_type}'"].map { |r| [r[:product_code], r[:id]] }
    end

    def find_composition_level_pm_types(id)
      DB[:pm_types]
        .join(:pm_composition_levels, id: :pm_composition_level_id)
        .where(pm_composition_level_id: id)
        .order(:pm_type_code)
        .select_map(:pm_type_code)
    end

    def for_select_pm_type_subtypes(pm_bom_id = nil)
      where = pm_bom_id.nil? ? '' : " WHERE pm_types.id NOT IN (#{bom_product_types(pm_bom_id).join(',')})"
      query = <<~SQL
        SELECT pm_types.pm_type_code || ' - ' || pm_subtypes.subtype_code AS subtype, pm_subtypes.id
        FROM pm_subtypes
        JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
        #{where}
        ORDER BY 1
      SQL
      DB[query]
        .select_map(%i[subtype id])
    end

    def for_select_non_fruit_composition_subtypes
      query = <<~SQL
        SELECT pm_types.pm_type_code || ' - ' || pm_subtypes.subtype_code AS subtype, pm_subtypes.id
        FROM pm_subtypes
        JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
        JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
        WHERE pm_composition_levels.composition_level != ?
        ORDER BY 1
      SQL
      DB[query, fruit_composition_level]
        .select_map(%i[subtype id])
    end

    def bom_product_types(pm_bom_id)
      DB[:pm_boms_products]
        .join(:pm_products, id: :pm_product_id)
        .join(:pm_subtypes, id: :pm_subtype_id)
        .join(:pm_types, id: :pm_type_id)
        .where(pm_bom_id: pm_bom_id)
        .distinct(Sequel[:pm_types][:id])
        .select_map(Sequel[:pm_types][:id])
    end

    def composition_levels
      DB[:pm_composition_levels]
        .order(:composition_level)
        .select_map(%i[description id])
    end

    def pm_composition_levels
      DB[:pm_composition_levels]
        .order(:composition_level)
        .select_map(%i[composition_level description])
    end

    def find_packaging_marks_by_fruitspec_mark(pm_mark_id)
      DB[:pm_marks].where(id: pm_mark_id).get(:packaging_marks)
    end

    def reorder_composition_levels(sorted_ids)
      upd = []
      sorted_ids.split(',').each_with_index do |id, index|
        upd << "UPDATE pm_composition_levels SET composition_level = #{index + 1} WHERE id = #{id};"
      end
      DB[upd.join].update
    end

    def update_uom_code(bom_product_id, uom_code)
      uom_id = DB[:uoms].where(uom_code: uom_code).get(:id)
      update(:pm_boms_products, bom_product_id, uom_id: uom_id)

      success_response("UOM updated to #{uom_code}",  uom_code: uom_code)
    end

    def update_quantity(bom_product_id, quantity)
      update(:pm_boms_products, bom_product_id, quantity: quantity)

      success_response("Quantity updated to #{quantity}", quantity: quantity)
    end

    def pm_type_codes(pm_type_ids)
      DB[:pm_types].where(id: pm_type_ids).select_map(:pm_type_code)
    end

    def pm_subtype_types(pm_subtype_ids)
      DB[:pm_subtypes].where(id: pm_subtype_ids).select_map(:pm_type_id)
    end

    def pm_subtype_codes(pm_subtype_ids)
      DB[:pm_subtypes].where(id: pm_subtype_ids).select_map(:subtype_code)
    end

    def pm_product_subtypes(pm_product_ids)
      DB[:pm_products].where(id: pm_product_ids).select_map(:pm_subtype_id)
    end

    def find_pm_type_by_subtype(subtype_id)
      DB[:pm_subtypes]
        .where(id: subtype_id)
        .get(:pm_type_id)
    end

    def find_uom_by_code(uom_code)
      DB[:uoms].where(uom_code: uom_code).get(:id)
    end

    def find_pm_bom_products(id)
      DB[:pm_boms_products]
        .join(:pm_products, id: :pm_product_id)
        .where(pm_bom_id: id)
        .order(:product_code)
        .select_map(:product_code)
    end

    def delete_pm_bom(id)
      DB[:pm_boms_products].where(pm_bom_id: id).delete
      DB[:pm_boms].where(id: id).delete
      { success: true }
    end

    def pm_bom_system_code(bom_id)
      query = <<~SQL
        SELECT string_agg(product_codes.product_code, '_'::text) AS system_code
        FROM (
          SELECT CASE WHEN pm_composition_levels.composition_level = 1 THEN pm_products.product_code::text
                 ELSE concat(pm_boms_products.quantity::text, 'x'::text, pm_products.product_code::text)
                 END AS product_code
          FROM pm_boms_products
          JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
          JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
          JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
          JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
          WHERE pm_boms_products.pm_bom_id = ?
          ORDER BY pm_composition_levels.composition_level
        ) product_codes
      SQL
      DB[query, bom_id].first[:system_code]
    end

    def refresh_system_codes
      ar = []
      DB[:pm_boms].all.map { |b| b[:id] }.each do |bom_id|
        system_code = pm_bom_system_code(bom_id)
        ar << "UPDATE pm_boms SET bom_code = '#{system_code}', system_code = '#{system_code}' WHERE id = #{bom_id};"
      end
      DB[ar.join].update
    end

    def minimum_composition_level?(pm_subtype_id)
      subtype_composition_description(pm_subtype_id) == composition_level_description(minimum_composition_level)
    end

    def subtype_composition_description(pm_subtype_id)
      DB[:pm_subtypes]
        .join(:pm_types, id: :pm_type_id)
        .join(:pm_composition_levels, id: :pm_composition_level_id)
        .where(Sequel[:pm_subtypes][:id] => pm_subtype_id)
        .get(Sequel[:pm_composition_levels][:description])
    end

    def minimum_composition_level
      DB['SELECT MIN(composition_level) FROM pm_composition_levels'].single_value
    end

    def composition_level_description(composition_level)
      DB[:pm_composition_levels].where(composition_level: composition_level).get(:description)
    end

    def fruit_composition_level
      DB[:pm_composition_levels].where(description: AppConst::FRUIT_PM_TYPE).get(:composition_level)
    end

    def fruit_composition_level?(pm_subtype_id)
      subtype_composition_description(pm_subtype_id) == AppConst::FRUIT_PM_TYPE
    end

    def one_level_up_fruit_composition?(pm_subtype_id)
      subtype_composition_description(pm_subtype_id) == composition_level_description(fruit_composition_level - 1)
    end

    def can_edit_product_code?(pm_subtype_id)
      fruit_composition = fruit_composition_level
      subtype_composition_level = subtype_composition_level(pm_subtype_id)
      return false if [minimum_composition_level, fruit_composition, fruit_composition - 1].include?(subtype_composition_level)

      true
    end

    def calculate_bom_weights(pm_bom_id) # rubocop:disable Metrics/AbcSize
      gross_weight = 0.0
      nett_weight = 0.0
      bom_products(pm_bom_id).each do |pm_product|
        product_weight = case pm_product[:composition_level]
                         when minimum_composition_level
                           pm_product[:quantity] * basic_pack_material_mass(pm_product[:basic_pack_id]).to_f
                         when fruit_composition_level
                           nett_weight = pm_product[:quantity] * fruit_average_weight(pm_product[:product_code]).to_f
                           nett_weight
                         else
                           pm_product[:quantity] * pm_product[:material_mass].to_f
                         end

        gross_weight += product_weight
      end

      update(:pm_boms, pm_bom_id, { gross_weight: gross_weight, nett_weight: nett_weight })
      { success: true }
    end

    def bom_products(pm_bom_id)
      query = <<~SQL
        SELECT pm_boms_products.pm_product_id, pm_products.product_code, pm_boms_products.quantity,
               pm_products.material_mass, pm_composition_levels.composition_level,
               pm_products.basic_pack_id
        FROM pm_boms_products
        JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
        JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
        JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
        JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
        WHERE pm_boms_products.pm_bom_id = #{pm_bom_id}
        ORDER BY pm_composition_levels.composition_level
      SQL
      DB[query]
        .all
    end

    def basic_pack_material_mass(basic_pack_id)
      return 0 if basic_pack_id.nil_or_empty?

      DB[:standard_pack_codes]
        .where(basic_pack_code_id:  basic_pack_id)
        .get(:material_mass)
    end

    def fruit_average_weight(product_code)
      res = product_code.split('_')
      commodity_id = find_commodity_by_code(res[0])
      DB[:std_fruit_size_counts]
        .where(size_count_value: res[1])
        .where(commodity_id: commodity_id)
        .get(:average_weight_gm)
    end

    def find_commodity_by_code(commodity_code)
      DB[:commodities]
        .where(code: commodity_code)
        .get(:id)
    end

    def for_select_fruitspec_pm_marks(where: nil)
      ds = DB[:pm_marks].order(:packaging_marks)
      ds = ds.where(where) unless where.nil?
      ds.select_map(%i[packaging_marks id])
    end

    def subtype_composition_level(pm_subtype_id)
      DB[:pm_subtypes]
        .join(:pm_types, id: :pm_type_id)
        .join(:pm_composition_levels, id: :pm_composition_level_id)
        .where(Sequel[:pm_subtypes][:id] => pm_subtype_id)
        .get(:composition_level)
    end

    def pm_product_basic_pack(basic_pack_id)
      DB[:basic_pack_codes]
        .where(id: basic_pack_id)
        .get(:basic_pack_code)
    end

    def pm_product_product_code(pm_product) # rubocop:disable Metrics/AbcSize
      type_short_code = find_type_short_code(find_pm_type_by_subtype(pm_product[:pm_subtype_id]))
      subtype_short_code = find_subtype_short_code(pm_product[:pm_subtype_id])
      product_code = case pm_product[:composition_level]
                     when minimum_composition_level
                       "#{type_short_code}_#{pm_product[:basic_pack_code]}_#{subtype_short_code}_#{pm_product[:height_mm]}"
                     when fruit_composition_level - 1
                       gross_weight_per_unit = pm_product[:gross_weight_per_unit].nil_or_empty? ? '*' : pm_product[:gross_weight_per_unit].to_f
                       items_per_unit = pm_product[:items_per_unit].nil_or_empty? ? '*' : pm_product[:items_per_unit]
                       "#{type_short_code}_#{gross_weight_per_unit}_#{subtype_short_code}_#{items_per_unit}"
                     else
                       pm_product[:product_code]
                     end
      product_code
    end

    def find_type_short_code(pm_type_id)
      DB[:pm_types]
        .where(id: pm_type_id)
        .get(:short_code)
    end

    def find_subtype_short_code(pm_subtype_id)
      DB[:pm_subtypes]
        .where(id: pm_subtype_id)
        .get(:short_code)
    end

    def find_std_fruit_size_by_product_code(product_code)
      arr = product_code.split('_')
      std_fruit_size_count_id =  DB[:std_fruit_size_counts]
                                 .where(size_count_value: arr[1])
                                 .where(commodity_id: DB[:commodities]
                                                        .where(code: arr[0])
                                                        .get(:id))
                                 .get(:id)

      DB[:std_fruit_size_counts].where(id: std_fruit_size_count_id).first
    end

    def sync_pm_boms # rubocop:disable Metrics/AbcSize
      pm_composition_level_id = get_id_or_create(:pm_composition_levels,
                                                 composition_level: AppConst::FRUIT_COMPOSITION_LEVEL,
                                                 description: AppConst::FRUIT_PM_TYPE)
      pm_type_id = get_id_or_create(:pm_types,
                                    pm_composition_level_id: pm_composition_level_id,
                                    pm_type_code: AppConst::FRUIT_PM_TYPE,
                                    description: AppConst::FRUIT_PM_TYPE)

      select_values(:std_fruit_size_counts, :id).each do |id|
        rec = FruitSizeRepo.new.find_std_fruit_size_count(id).to_h
        pm_subtype_id = get_id_or_create(:pm_subtypes,
                                         pm_type_id: pm_type_id,
                                         subtype_code: rec[:commodity_code],
                                         description: rec[:commodity_code])
        next if exists?(:pm_products, product_code: rec[:product_code])

        create_pm_product(
          pm_subtype_id: pm_subtype_id,
          std_fruit_size_count_id: id,
          product_code: rec[:product_code],
          erp_code: rec[:product_code],
          description: rec[:description]
        )
      end
    end
  end
end
