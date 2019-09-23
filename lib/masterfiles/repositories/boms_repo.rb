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

    crud_calls_for :pm_types, name: :pm_type, wrapper: PmType
    crud_calls_for :pm_subtypes, name: :pm_subtype, wrapper: PmSubtype
    crud_calls_for :pm_products, name: :pm_product, wrapper: PmProduct
    crud_calls_for :pm_boms, name: :pm_bom, wrapper: PmBom
    crud_calls_for :pm_boms_products, name: :pm_boms_product, wrapper: PmBomsProduct

    def find_pm_type_subtypes(id)
      DB[:pm_subtypes]
        .join(:pm_types, id: :pm_type_id)
        .where(pm_type_id: id)
        .order(:subtype_code)
        .select_map(:subtype_code)
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
        .select(
          :id,
          :uom_code
        ).map { |r| [r[:uom_code], r[:id]] }
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
                                                     flatten_columns: { subtype_code: :subtype_code } }])
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
  end
end
