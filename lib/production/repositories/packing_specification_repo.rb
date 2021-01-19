# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationRepo < BaseRepo
    build_for_select :packing_specifications, label: :packing_specification_code, value: :id, order_by: :packing_specification_code
    build_inactive_select :packing_specifications, label: :packing_specification_code,  value: :id, order_by: :packing_specification_code
    crud_calls_for :packing_specifications, name: :packing_specification, wrapper: PackingSpecification

    build_for_select :packing_specification_items, label: :description, value: :id, order_by: :description
    build_inactive_select :packing_specification_items, label: :description, value: :id, order_by: :description
    crud_calls_for :packing_specification_items, name: :packing_specification_item, wrapper: PackingSpecificationItem

    def find_packing_specification(id)
      hash = find_with_association(:packing_specifications, id,
                                   parent_tables: [{ parent_table: :product_setup_templates,
                                                     columns: [:template_name],
                                                     flatten_columns: { template_name: :product_setup_template } }],
                                   lookup_functions: [{ function: :fn_current_status,
                                                        args: ['packing_specifications', :id],
                                                        col_name: :status }])
      return nil if hash.nil?

      PackingSpecification.new(hash)
    end

    def find_packing_specification_item(id)
      query = <<~SQL
        SELECT
          packing_specification_items.id,
          packing_specification_items.packing_specification_id,
          packing_specifications.packing_specification_code,
          packing_specification_items.description,
          packing_specification_items.pm_bom_id,
          pm_boms.bom_code AS pm_bom,
          packing_specification_items.pm_mark_id,
          pm_marks.description AS pm_mark,
          packing_specification_items.product_setup_id,
          fn_product_setup_code(packing_specification_items.product_setup_id) AS product_setup,
          packing_specification_items.tu_labour_product_id,
          pm_products_tu.erp_code AS tu_labour_product,
          packing_specification_items.ru_labour_product_id,
          pm_products_ru.erp_code AS ru_labour_product,
          packing_specification_items.ri_labour_product_id,
          pm_products_ri.erp_code AS ri_labour_product,
          packing_specification_items.fruit_sticker_ids,
          (SELECT array_agg(product_code) FROM pm_products WHERE pm_products.id = ANY(packing_specification_items.fruit_sticker_ids) GROUP BY packing_specification_items.id) AS fruit_stickers,
          packing_specification_items.tu_sticker_ids,
          (SELECT array_agg(product_code) FROM pm_products WHERE pm_products.id = ANY(packing_specification_items.tu_sticker_ids) GROUP BY packing_specification_items.id) AS tu_stickers,
          packing_specification_items.ru_sticker_ids,
          (SELECT array_agg(product_code) FROM pm_products WHERE pm_products.id = ANY(packing_specification_items.ru_sticker_ids) GROUP BY packing_specification_items.id) AS ru_stickers,
          packing_specification_items.active,
          packing_specification_items.created_at,
          packing_specification_items.updated_at,
          fn_current_status('packing_specification_items', packing_specification_items.id) AS status
        FROM packing_specification_items
        JOIN packing_specifications ON packing_specifications.id = packing_specification_items.packing_specification_id
        LEFT JOIN pm_boms ON pm_boms.id = packing_specification_items.pm_bom_id
        LEFT JOIN pm_marks ON pm_marks.id = packing_specification_items.pm_mark_id
        LEFT JOIN pm_products pm_products_tu ON pm_products_tu.id = packing_specification_items.tu_labour_product_id
        LEFT JOIN pm_products pm_products_ru ON pm_products_ru.id = packing_specification_items.ru_labour_product_id
        LEFT JOIN pm_products pm_products_ri ON pm_products_ri.id = packing_specification_items.ri_labour_product_id

        WHERE packing_specification_items.id = ?
      SQL
      hash = DB[query, id].first
      return nil if hash.nil?

      PackingSpecificationItem.new(hash)
    end

    def create_packing_specification_item(res)
      params = res.to_h.transform_values { |v| v.is_a?(Array) ? Sequel.pg_array(v, :integer) : v }
      id = get_id(:packing_specification_items, params)
      raise Crossbeams::InfoError, 'This packing specification item already exists' if id

      create(:packing_specification_items, params)
    end

    def refresh_packing_specification_items(user)
      packing_specifications = select_values(:packing_specifications,
                                             %i[id product_setup_template_id])
      packing_specifications.each do |packing_specification_id, product_setup_template_id|
        product_setup_ids = select_values(:product_setups,
                                          :id,
                                          { product_setup_template_id: product_setup_template_id })
        existing_ids = select_values(:packing_specification_items,
                                     :product_setup_id,
                                     { packing_specification_id: packing_specification_id })
        (product_setup_ids - existing_ids).each do |product_setup_id|
          item_id = create_packing_specification_item(
            packing_specification_id: packing_specification_id,
            product_setup_id: product_setup_id,
            pm_bom_id: get(:product_setups, product_setup_id, :pm_bom_id),
            pm_mark_id: get(:product_setups, product_setup_id, :pm_mark_id),
            fruit_sticker_ids: [],
            tu_sticker_ids: [],
            ru_sticker_ids: []
          )
          log_status(:packing_specification_items, item_id, 'CREATED', user_name: user.user_name)
        end
      end
    end
  end
end
