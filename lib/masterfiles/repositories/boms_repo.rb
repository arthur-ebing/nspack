# frozen_string_literal: true

module MasterfilesApp
  class BomsRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :pm_types,
                     label: :pm_type_code,
                     value: :id,
                     order_by: :pm_type_code
    build_inactive_select :pm_types,
                          label: :pm_type_code,
                          value: :id,
                          order_by: :pm_type_code

    build_for_select :pm_subtypes,
                     label: :subtype_code,
                     value: :id,
                     order_by: :subtype_code
    build_inactive_select :pm_subtypes,
                          label: :subtype_code,
                          value: :id,
                          order_by: :subtype_code

    build_for_select :pm_products,
                     label: :product_code,
                     value: :id,
                     order_by: :product_code
    build_inactive_select :pm_products,
                          label: :product_code,
                          value: :id,
                          order_by: :product_code

    build_for_select :pm_boms,
                     label: :bom_code,
                     value: :id,
                     order_by: :bom_code
    build_inactive_select :pm_boms,
                          label: :bom_code,
                          value: :id,
                          order_by: :bom_code

    build_for_select :pm_boms_products,
                     label: :quantity,
                     value: :id,
                     order_by: :quantity
    build_inactive_select :pm_boms_products,
                          label: :quantity,
                          value: :id,
                          order_by: :quantity

    build_for_select :pm_composition_levels,
                     label: :description,
                     value: :id,
                     order_by: :description
    build_inactive_select :pm_composition_levels,
                          label: :description,
                          value: :id,
                          order_by: :description

    crud_calls_for :pm_types, name: :pm_type, wrapper: PmType
    crud_calls_for :pm_subtypes, name: :pm_subtype, wrapper: PmSubtype
    crud_calls_for :pm_products, name: :pm_product, wrapper: PmProduct
    crud_calls_for :pm_boms, name: :pm_bom, wrapper: PmBom
    crud_calls_for :pm_boms_products, name: :pm_boms_product, wrapper: PmBomsProduct
    crud_calls_for :pm_composition_levels, name: :pm_composition_level, wrapper: PmCompositionLevel

    def find_pm_type_subtypes(id)
      DB[:pm_subtypes]
        .join(:pm_types, id: :pm_type_id)
        .where(pm_type_id: id)
        .order(:subtype_code)
        .select_map(:subtype_code)
    end

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
      hash = find_with_association(:pm_products,
                                   id,
                                   parent_tables: [{ parent_table: :pm_subtypes,
                                                     columns: [:subtype_code],
                                                     flatten_columns: { subtype_code: :subtype_code } },
                                                   { parent_table: :basic_pack_codes,
                                                     columns: [:basic_pack_code],
                                                     foreign_key: :basic_pack_id,
                                                     flatten_columns: { basic_pack_code: :basic_pack_code } }])
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

    def for_select_pm_subtype_pm_boms(pm_subtype_id)  # rubocop:disable Metrics/AbcSize
      DB[:pm_boms]
        .join(:pm_boms_products, pm_bom_id: :id)
        .join(:pm_products, id: :pm_product_id)
        .join(:pm_subtypes, id: :pm_subtype_id)
        .where(pm_subtype_id: pm_subtype_id)
        .distinct(Sequel[:pm_boms][:id])
        .select(
          Sequel[:pm_boms][:id],
          Sequel[:pm_boms][:bom_code]
        ).map { |r| [r[:bom_code], r[:id]] }
    end

    def pm_bom_products(id)
      query = <<~SQL
        SELECT product_code,pm_type_code, subtype_code, uom_code, quantity
        FROM pm_products
        JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
        JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
        JOIN pm_boms_products ON pm_products.id = pm_boms_products.pm_product_id
        JOIN uoms ON uoms.id = pm_boms_products.uom_id
        WHERE pm_bom_id = #{id}
        ORDER BY product_code
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

    def bom_product_types(pm_bom_id)
      DB[:pm_boms_products]
        .join(:pm_products, id: :pm_product_id)
        .join(:pm_subtypes, id: :pm_subtype_id)
        .join(:pm_types, id: :pm_type_id)
        .where(pm_bom_id: pm_bom_id)
        .distinct(Sequel[:pm_types][:id])
        .select_map(Sequel[:pm_types][:id])
    end

    def pm_composition_level_exists?(description)
      exists?(:pm_composition_levels, description: description)
    end

    def find_pm_composition_level_by_code(description)
      DB[:pm_composition_levels].where(description: description).get(:id)
    end

    def pm_type_code_exists?(pm_type_code)
      exists?(:pm_types, pm_type_code: pm_type_code)
    end

    def find_pm_type_by_code(pm_type_code)
      DB[:pm_types].where(pm_type_code: pm_type_code).get(:id)
    end

    def pm_subtype_code_exists?(subtype_code)
      exists?(:pm_subtypes, subtype_code: subtype_code)
    end

    def find_pm_subtype_by_code(subtype_code)
      DB[:pm_subtypes].where(subtype_code: subtype_code).get(:id)
    end

    def pm_bom_code_exists?(bom_code)
      exists?(:pm_boms, bom_code: bom_code)
    end

    def find_pm_bom_by_code(bom_code)
      DB[:pm_boms].where(bom_code: bom_code).get(:id)
    end

    def pm_product_code_exists?(product_code)
      exists?(:pm_products, product_code: product_code)
    end

    def find_pm_product_by_code(product_code)
      DB[:pm_products].where(product_code: product_code).get(:id)
    end

    def composition_levels
      DB[:pm_composition_levels]
        .order(:composition_level)
        .select_map(%i[description id])
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

      success_response("UOM updated to #{uom_code}", uom_code: uom_code)
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
          SELECT pm_products.product_code
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
  end
end
