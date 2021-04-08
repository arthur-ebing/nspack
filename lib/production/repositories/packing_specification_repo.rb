# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :packing_specification_items,
                     label: :description,
                     value: :id,
                     order_by: :description
    build_inactive_select :packing_specification_items,
                          label: :description,
                          value: :id,
                          order_by: :description
    crud_calls_for :packing_specification_items, name: :packing_specification_item, exclude: [:update]

    def find_packing_specification_item(id)
      query = <<~SQL
        SELECT
          packing_specification_items.id,
          packing_specification_items.description,
          packing_specification_items.pm_bom_id,
          pm_boms.bom_code AS pm_bom,
          packing_specification_items.pm_mark_id,
          product_setups.mark_id AS mark_id,
          product_setups.std_fruit_size_count_id AS std_fruit_size_count_id,
          product_setups.basic_pack_code_id AS basic_pack_id,
          fn_pkg_mark(pm_marks.id) AS pm_mark,
          packing_specification_items.product_setup_id,
          product_setups.product_setup_template_id,
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

    def update_packing_specification_item(id, res)
      attrs = res.to_h
      legacy_data = UtilityFunctions.symbolize_keys(get(:packing_specification_items, id, :legacy_data).to_h)

      attrs[:legacy_data] = legacy_data.merge(attrs[:legacy_data].to_h)
      update(:packing_specification_items, id, attrs)
    end

    def get(table_name, id, column)
      return nil if id.nil_or_empty?

      DB[table_name].where(id: id.to_i).get(column)
    end

    def extend_packing_specification(hash) # rubocop:disable Metrics/AbcSize
      hash[:step] ||= 4
      product_setup_template = ProductionApp::ProductSetupRepo.new.find_product_setup_template(hash[:product_setup_template_id])
      hash[:product_setup_template] = get(:product_setup_templates, hash[:product_setup_template_id], :template_name)
      hash[:cultivar_group_id] ||= product_setup_template&.cultivar_group_id
      hash[:cultivar_group] ||= product_setup_template&.cultivar_group_code
      hash[:cultivar_id] ||= product_setup_template&.cultivar_id
      hash[:cultivar] = product_setup_template&.cultivar_name
      hash[:packing_specification_code] = product_setup_partial_code(hash)
      return hash if hash[:step] < 1

      hash[:commodity_id] ||= ProductionApp::ProductSetupRepo.new.get_commodity_id(hash[:cultivar_group_id], hash[:cultivar_id])
      hash[:requires_standard_counts] ||= get(:commodities, hash[:commodity_id], :requires_standard_counts) || true
      hash[:commodity] = get(:commodities, hash[:commodity_id], :code)
      hash[:marketing_variety] = get(:marketing_varieties, hash[:marketing_variety_id], :marketing_variety_code)
      hash[:std_fruit_size_count] = MasterfilesApp::FruitSizeRepo.new.find_std_fruit_size_count(hash[:std_fruit_size_count_id])&.size_count_value
      hash[:basic_pack] = get(:basic_pack_codes, hash[:basic_pack_code_id], :basic_pack_code)
      hash[:standard_pack] = get(:standard_pack_codes, hash[:standard_pack_code_id], :standard_pack_code)
      hash[:fruit_actual_counts_for_pack] = get(:fruit_actual_counts_for_packs, hash[:fruit_actual_counts_for_pack_id], :actual_count_for_pack)
      hash[:fruit_size_reference] = get(:fruit_size_references, hash[:fruit_size_reference_id], :size_reference)
      hash[:grade] = get(:grades, hash[:grade_id], :grade_code)
      hash[:class] = get(:rmt_classes, hash[:rmt_class_id], :rmt_class_code)
      hash[:packing_specification_code] = product_setup_partial_code(hash)
      return hash if hash[:step] < 2

      marketing_org_party_role = MasterfilesApp::PartyRepo.new.find_party_role(hash[:marketing_org_party_role_id])
      hash[:marketing_org] = marketing_org_party_role&.party_name
      hash[:marketing_org_description] = get(:organizations, marketing_org_party_role&.organization_id, :short_description)
      hash[:packed_tm_group] = get(:target_market_groups, hash[:packed_tm_group_id], :target_market_group_name)
      hash[:target_market] = get(:target_markets, hash[:target_market_id], :target_market_name)
      hash[:mark] = get(:marks, hash[:mark_id], :mark_code)
      hash[:inventory_code] = get(:inventory_codes, hash[:inventory_code_id], :inventory_code)
      hash[:customer_variety] = MasterfilesApp::MarketingRepo.new.find_customer_variety(hash[:customer_variety_id])&.variety_as_customer_variety
      hash[:packing_specification_code] = product_setup_partial_code(hash)
      return hash if hash[:step] < 3

      hash[:treatments] = ProductionApp::ProductSetupRepo.new.find_treatment_codes(hash[:product_setup_id]).to_a.join(', ')
      return hash if hash[:step] < 4

      hash[:pallet_base] = get(:pallet_bases, hash[:pallet_base_id], :pallet_base_code)
      hash[:pallet_stack_type] = get(:pallet_stack_types, hash[:pallet_stack_type_id], :stack_type_code)
      hash[:stack_height] = get(:pallet_stack_types, hash[:pallet_stack_type_id], :stack_height)
      hash[:pallet_format] = get(:pallet_formats, hash[:pallet_format_id], :description)
      hash[:pallet_label] = get(:label_templates, hash[:pallet_label_name], :label_template_name)
      hash[:cartons_per_pallet] = get(:cartons_per_pallet, hash[:cartons_per_pallet_id], :cartons_per_pallet)
      hash[:packing_specification_code] = product_setup_partial_code(hash)
      hash
    end

    def product_setup_partial_code(hash)
      product_setup_components = %i[cultivar marketing_variety grade
                                    std_fruit_size_count fruit_actual_counts_for_pack
                                    fruit_size_reference basic_pack marketing_org_description
                                    packed_tm_group mark inventory_code
                                    pallet_base stack_height cartons_per_pallet]

      components = product_setup_components
      components = product_setup_components - %i[std_fruit_size_count fruit_actual_counts_for_pack] unless hash[:requires_standard_counts]

      code = (hash[:commodity]).to_s
      components.each { |k| code = "#{code}_#{hash[k]}" }
      code
    end

    def lookup_existing_packing_specification_item_id(res) # rubocop:disable Metrics/AbcSize
      args = res.to_h
      fruit_ids = args.delete(:fruit_sticker_ids)
      tu_ids = args.delete(:tu_sticker_ids)
      ru_ids = args.delete(:ru_sticker_ids)

      select_values(:packing_specification_item, %i[id fruit_sticker_ids tu_sticker_ids ru_sticker_ids], args).each do |id, fruit, tu, ru|
        return id if (Array(fruit).to_set == Array(fruit_ids).to_set) && (Array(tu).to_set == Array(tu_ids).to_set) && (Array(ru).to_set == Array(ru_ids).to_set)
      end
      nil
    end

    def delete_packing_specification_item(id)
      product_setup_id = get(:packing_specification_items, id, :product_setup_id)
      item_ids = select_values(:packing_specification_items, :id, product_setup_id: product_setup_id)
      delete(:packing_specification_items, id)
      delete(:product_setups, product_setup_id) if item_ids.length == 1
    end
  end
end
