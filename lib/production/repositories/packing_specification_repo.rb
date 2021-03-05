# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :packing_specifications, label: :packing_specification_code, value: :id, order_by: :packing_specification_code
    build_inactive_select :packing_specifications, label: :packing_specification_code, value: :id, order_by: :packing_specification_code
    crud_calls_for :packing_specifications, name: :packing_specification, wrapper: PackingSpecification

    build_for_select :packing_specification_items, label: :description, value: :id, order_by: :description
    build_inactive_select :packing_specification_items, label: :description, value: :id, order_by: :description
    crud_calls_for :packing_specification_items, name: :packing_specification_item, wrapper: PackingSpecificationItem

    def find_packing_specification(id)
      hash = find_with_association(
        :packing_specifications, id,
        parent_tables: [{ parent_table: :product_setup_templates,
                          columns: %i[template_name packhouse_resource_id production_line_id],
                          flatten_columns: { template_name: :product_setup_template,
                                             packhouse_resource_id: :packhouse_resource_id,
                                             production_line_id: :production_line_id } },
                        { parent_table: :cultivar_groups,
                          columns: [:cultivar_group_code],
                          flatten_columns: { cultivar_group_code: :cultivar_group_code } }],
        lookup_functions: [{ function: :fn_current_status,
                             args: ['packing_specifications', :id],
                             col_name: :status }]
      )
      return nil unless hash

      hash[:packhouse] = get(:plant_resources, hash[:packhouse_resource_id], :plant_resource_code)
      hash[:line] = get(:plant_resources, hash[:production_line_id], :plant_resource_code)
      PackingSpecification.new(hash)
    end

    def find_packing_specification_item(id)
      query = <<~SQL
        SELECT
          packing_specification_items.id,
          packing_specification_items.packing_specification_id,
          packing_specifications.packing_specification_code AS packing_specification,
          packing_specification_items.description,
          packing_specification_items.pm_bom_id,
          pm_boms.bom_code AS pm_bom,
          packing_specification_items.pm_mark_id,
          product_setups.mark_id AS mark_id,
          product_setups.std_fruit_size_count_id AS std_fruit_size_count_id,
          product_setups.basic_pack_code_id AS basic_pack_id,
          fn_pkg_mark(pm_marks.id) AS pm_mark,
          packing_specification_items.product_setup_id,
          packing_specifications.product_setup_template_id,
          fn_product_setup_code(packing_specification_items.product_setup_id) AS product_setup,
          packing_specification_items.tu_labour_product_id,
          pm_products_tu.erp_code AS tu_labour_product,
          packing_specification_items.ru_labour_product_id,
          pm_products_ru.erp_code AS ru_labour_product,
          packing_specification_items.ri_labour_product_id,
          pm_products_ri.erp_code AS ri_labour_product,
          packing_specification_items.fruit_sticker_ids,
          (SELECT product_code FROM pm_products WHERE pm_products.id = fruit_sticker_ids[1] ) AS fruit_sticker_1,
          (SELECT product_code FROM pm_products WHERE pm_products.id = fruit_sticker_ids[2] ) AS fruit_sticker_2,
          (SELECT array_agg(product_code) FROM pm_products WHERE pm_products.id = ANY(packing_specification_items.fruit_sticker_ids) GROUP BY packing_specification_items.id) AS fruit_stickers,
          packing_specification_items.tu_sticker_ids,
          (SELECT product_code FROM pm_products WHERE pm_products.id = tu_sticker_ids[1] ) AS tu_sticker_1,
          (SELECT product_code FROM pm_products WHERE pm_products.id = tu_sticker_ids[2] ) AS tu_sticker_2,
          (SELECT array_agg(product_code) FROM pm_products WHERE pm_products.id = ANY(packing_specification_items.tu_sticker_ids) GROUP BY packing_specification_items.id) AS tu_stickers,
          packing_specification_items.ru_sticker_ids,
          (SELECT product_code FROM pm_products WHERE pm_products.id = ru_sticker_ids[1] ) AS ru_sticker_1,
          (SELECT product_code FROM pm_products WHERE pm_products.id = ru_sticker_ids[2] ) AS ru_sticker_2,
          (SELECT array_agg(product_code) FROM pm_products WHERE pm_products.id = ANY(packing_specification_items.ru_sticker_ids) GROUP BY packing_specification_items.id) AS ru_stickers,
          packing_specification_items.active,
          packing_specification_items.created_at,
          packing_specification_items.updated_at,
          fn_current_status('packing_specification_items', packing_specification_items.id) AS status,
          fn_packing_specification_code(packing_specification_items.id) AS packing_specification_item_code
        FROM packing_specification_items
        JOIN packing_specifications ON packing_specifications.id = packing_specification_items.packing_specification_id
        JOIN product_setups ON product_setups.id = packing_specification_items.product_setup_id
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

    def inline_update_packing_specification_item(id, params) # rubocop:disable Metrics/AbcSize
      case params[:column_name]
      when 'description'
        column = 'description'
        value = params[:column_value]

      when 'pm_mark'
        column = 'pm_mark_id'
        ar = params[:column_value].split('_')

        mark_id = get_id(:marks, mark_code: ar.shift)
        value = get_id(:pm_marks, mark_id: mark_id, packaging_marks: array_of_text_for_db_col(ar))

      when 'pm_bom'
        column = 'pm_bom_id'
        value = get_id(:pm_boms, bom_code: params[:column_value])

      when 'tu_labour_product', 'ru_labour_product', 'ri_labour_product'
        column = params[:column_name].gsub('_product', '_product_id')
        value = get_id(:pm_products, product_code: params[:column_value])

      when 'fruit_sticker_1', 'tu_sticker_1', 'ru_sticker_1', 'fruit_sticker_2', 'tu_sticker_2', 'ru_sticker_2'
        column = params[:column_name].gsub(/_[12]/, '_ids').to_sym
        indexer = params[:column_name][-1].to_i - 1
        current_value = get(:packing_specification_items, id, column)
        current_value[indexer] = get_id(:pm_products, product_code: params[:column_value])
        value = current_value
      else
        raise Crossbeams::InfoError, "There is no handler for changed column #{params[:column_name]}"
      end

      update(:packing_specification_items, id, { column => value })
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
