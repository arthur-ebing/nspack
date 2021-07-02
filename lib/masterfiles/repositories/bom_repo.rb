# frozen_string_literal: true

module MasterfilesApp
  class BomRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_inactive_select :pm_types,
                          label: :pm_type_code,
                          value: :id,
                          order_by: :pm_type_code

    build_inactive_select :pm_subtypes,
                          label: :subtype_code,
                          value: :id,
                          order_by: :subtype_code

    build_inactive_select :pm_products,
                          label: :product_code,
                          value: :id,
                          order_by: :product_code

    build_inactive_select :pm_boms,
                          label: :bom_code,
                          value: :id,
                          order_by: :bom_code

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

    build_inactive_select :pm_marks,
                          label: :packaging_marks,
                          value: :id,
                          order_by: :packaging_marks

    crud_calls_for :pm_types, name: :pm_type
    crud_calls_for :pm_subtypes, name: :pm_subtype
    crud_calls_for :pm_products, name: :pm_product
    crud_calls_for :pm_boms, name: :pm_bom, wrapper: PmBom, exclude: %i[delete]
    crud_calls_for :pm_boms_products, name: :pm_boms_product
    crud_calls_for :pm_composition_levels, name: :pm_composition_level, wrapper: PmCompositionLevel
    crud_calls_for :pm_marks, name: :pm_mark

    def find_pm_type(id)
      find_with_association(:pm_types,
                            id,
                            parent_tables: [{ parent_table: :pm_composition_levels,
                                              columns: %i[composition_level description],
                                              flatten_columns: { composition_level: :composition_level,
                                                                 description: :composition_level_description } }],
                            wrapper: PmType)
    end

    def find_pm_subtype(id)
      hash = find_with_association(:pm_subtypes, id,
                                   parent_tables: [{ parent_table: :pm_types,
                                                     foreign_key: :pm_type_id,
                                                     columns: %i[pm_type_code pm_composition_level_id],
                                                     flatten_columns: { pm_type_code: :pm_type_code,
                                                                        pm_composition_level_id: :pm_composition_level_id } },
                                                   { parent_table: :pm_composition_levels,
                                                     foreign_key: :pm_composition_level_id,
                                                     columns: [:composition_level],
                                                     flatten_columns: { composition_level: :composition_level,
                                                                        description: :composition_level_description } }])
      return nil if hash.nil?

      hash[:minimum_composition_level] = hash[:composition_level] == DB[:pm_composition_levels].min(:composition_level)
      hash[:fruit_composition_level] = hash[:composition_level_description] == AppConst::PM_TYPE_FRUIT
      PmSubtype.new(hash)
    end

    def find_pm_product(id)
      find_with_association(:pm_products, id,
                            parent_tables: [{ parent_table: :pm_subtypes,
                                              columns: %i[subtype_code pm_type_id],
                                              flatten_columns: { subtype_code: :pm_subtype_code, pm_type_id: :pm_type_id } },
                                            { parent_table: :pm_types,
                                              foreign_key: :pm_type_id,
                                              columns: %i[pm_type_code pm_composition_level_id],
                                              flatten_columns: { pm_type_code: :pm_type_code,
                                                                 pm_composition_level_id: :pm_composition_level_id } },
                                            { parent_table: :pm_composition_levels,
                                              foreign_key: :pm_composition_level_id,
                                              columns: [:composition_level],
                                              flatten_columns: { composition_level: :composition_level,
                                                                 description: :composition_level_description } },
                                            { parent_table: :basic_pack_codes,
                                              foreign_key: :basic_pack_id,
                                              columns: [:basic_pack_code],
                                              flatten_columns: { basic_pack_code: :basic_pack_code } }],
                            wrapper: PmProduct)
    end

    def find_pm_boms_product(id)
      hash = find_with_association(:pm_boms_products, id,
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

      hash[:last_product] = select_values(:pm_boms_products, :id, pm_bom_id: hash[:pm_bom_id]).length <= 1
      PmBomsProduct.new(hash)
    end

    def find_pm_mark(id)
      find_with_association(:pm_marks, id,
                            parent_tables: [{ parent_table: :marks,
                                              columns: [:mark_code],
                                              flatten_columns: { mark_code: :mark_code } }],
                            wrapper: PmMark)
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
                 ORDER BY pm_composition_levels.composition_level ASC) cpp ON cpp.id = pm_boms_products.pm_product_id
          WHERE pm_boms.bom_code LIKE '%#{commodity_code}#{size_count}'
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

    def for_select_pm_boms(where: {}, exclude: {}, active: true)
      DB[:pm_boms]
        .left_outer_join(:pm_boms_products, pm_bom_id: Sequel[:pm_boms][:id])
        .left_outer_join(:pm_products, id: Sequel[:pm_boms_products][:pm_product_id])
        .where(Sequel[:pm_boms][:active] => active)
        .exclude(exclude)
        .where(where)
        .distinct
        .order(:bom_code)
        .select_map([:bom_code, Sequel[:pm_boms][:id]])
    end

    def for_select_packing_spec_pm_boms(where: {})
      query = <<~SQL
        SELECT pm_boms.bom_code, pm_boms.id
        FROM pm_boms
        WHERE pm_boms.active
        AND EXISTS (
            SELECT pm_products.id
            FROM pm_products JOIN pm_boms_products ON (pm_boms_products.pm_bom_id = pm_boms.id)
            WHERE pm_product_id = pm_products.id AND pm_products.std_fruit_size_count_id = ?)
        AND EXISTS (
            SELECT pm_products.id
            FROM pm_products JOIN pm_boms_products ON (pm_boms_products.pm_bom_id = pm_boms.id)
            WHERE pm_product_id = pm_products.id AND pm_products.basic_pack_id = ?)
        ORDER BY bom_code
      SQL
      DB[query, where[:std_fruit_size_count_id], where[:basic_pack_id]].select_map(%i[bom_code id])
    end

    def for_select_pm_marks(where: {}, active: true)
      DB[:pm_marks]
        .join(:marks, id: :mark_id)
        .where(Sequel[:pm_marks][:active] => active)
        .where(where)
        .order(:mark_code)
        .select(Sequel[:pm_marks][:id], Sequel.function(:fn_pkg_mark, Sequel[:pm_marks][:id]))
        .map { |r| [r[:fn_pkg_mark], r[:id]] }
    end

    def for_select_pm_boms_products(where: {}, active: true)
      DB[:pm_boms_products]
        .join(:pm_products, id: :pm_product_id)
        .where(Sequel[:pm_boms_products][:active] => active)
        .where(where)
        .order(:product_code)
        .select_map([:product_code, Sequel[:pm_boms_products][:id]])
    end

    def for_select_pm_products(where: {}, active: true)
      DB[:pm_products]
        .join(:pm_subtypes, id: :pm_subtype_id)
        .join(:pm_types, id: :pm_type_id).distinct
        .where(Sequel[:pm_products][:active] => active)
        .where(where)
        .order(:product_code)
        .select_map([:product_code, Sequel[:pm_products][:id]])
    end

    def for_select_pm_types(where: {}, exclude: {}, active: true) # rubocop:disable Metrics/AbcSize
      DB[:pm_types]
        .left_outer_join(:pm_composition_levels, id: :pm_composition_level_id)
        .left_outer_join(:pm_subtypes, pm_type_id: Sequel[:pm_types][:id])
        .left_outer_join(:pm_products, pm_subtype_id: Sequel[:pm_subtypes][:id])
        .distinct
        .where(Sequel[:pm_types][:active] => active)
        .exclude(exclude)
        .where(where)
        .order(:pm_type_code)
        .select_map([:pm_type_code, Sequel[:pm_types][:id]])
    end

    def for_select_pm_subtypes(where: {}, exclude: {}, active: true, grouped: false) # rubocop:disable Metrics/AbcSize
      ds = DB[:pm_subtypes]
           .join(:pm_types, id: :pm_type_id)
           .left_outer_join(:pm_products, pm_subtype_id: Sequel[:pm_subtypes][:id])
           .left_outer_join(:pm_boms_products, pm_product_id: Sequel[:pm_products][:id])
           .left_outer_join(:pm_composition_levels, id: Sequel[:pm_types][:pm_composition_level_id])
           .where(Sequel[:pm_subtypes][:active] => active)
           .where(where)
           .exclude(exclude)
           .distinct
      if grouped
        ds.order(:pm_type_code).select_map([:pm_type_code, :subtype_code, Sequel[:pm_subtypes][:id]]).group_by { |rec| rec.shift.to_sym }
      else
        ds.order(:subtype_code).select_map([:subtype_code, Sequel[:pm_subtypes][:id]])
      end
    end

    def composition_levels
      DB[:pm_composition_levels]
        .order(:composition_level)
        .select_map(%i[description id])
    end

    def list_pm_composition_levels
      DB[:pm_composition_levels]
        .order(:composition_level)
        .select_map(%i[composition_level description])
    end

    def inner_pm_marks_for_level(level)
      map = { '1': 'tu_mark', '2': 'ru_mark', '3': 'ri_mark' }
      DB[:inner_pm_marks]
        .where({ "#{map[level.to_sym]}": true }).select_map(%i[inner_pm_mark_code]).unshift('NONE')
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
      quantity = nil if quantity.empty?
      update(:pm_boms_products, bom_product_id, quantity: quantity)
    end

    def delete_pm_bom(id)
      DB[:pm_boms_products].where(pm_bom_id: id).delete
      DB[:pm_boms].where(id: id).delete
    end

    def pm_bom_system_code(pm_bom_id, exclude_subtype_id = nil)
      exclude_str = exclude_subtype_id.nil_or_empty? ? '' : " AND pm_subtypes.id != #{exclude_subtype_id}"

      query = <<~SQL
        SELECT string_agg(product_codes.product_code, '_'::text) AS system_code
        FROM (
          SELECT CASE WHEN pm_composition_levels.composition_level = 1 THEN pm_products.product_code::text
                 ELSE CONCAT(COALESCE(pm_boms_products.quantity::text, '*'), 'x'::text, pm_products.product_code::text)
                 END AS product_code
          FROM pm_boms_products
          JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
          JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
          JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
          JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
          WHERE pm_boms_products.pm_bom_id = ?
          #{exclude_str}
          ORDER BY pm_composition_levels.composition_level
        ) product_codes
      SQL
      DB[query, pm_bom_id].first[:system_code]
    end

    def calculate_bom_weights(pm_bom_id) # rubocop:disable Metrics/AbcSize
      gross_weight = 0.0
      nett_weight = 0.0
      bom_products(pm_bom_id).each do |row|
        pm_subtype = find_pm_subtype(row[:pm_subtype_id])
        product_weight = if pm_subtype.minimum_composition_level
                           row[:quantity] * row[:standard_pack_material_mass].to_f
                         elsif pm_subtype.fruit_composition_level
                           nett_weight = row[:quantity] * row[:average_weight_gm].to_f
                           nett_weight
                         else
                           row[:quantity] * row[:material_mass].to_f
                         end

        gross_weight += product_weight
      end
      update(:pm_boms, pm_bom_id, { gross_weight: gross_weight, nett_weight: nett_weight })
    end

    def bom_products(pm_bom_id)
      query = <<~SQL
        SELECT pm_boms_products.pm_product_id, pm_products.product_code, pm_boms_products.quantity,
               pm_products.material_mass, pm_composition_levels.composition_level,
               pm_products.basic_pack_id, pm_products.pm_subtype_id,
               std_fruit_size_counts.average_weight_gm, standard_pack_codes.material_mass AS standard_pack_material_mass
        FROM pm_boms_products
        JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
        JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
        JOIN pm_types ON pm_types.id = pm_subtypes.pm_type_id
        JOIN pm_composition_levels ON pm_composition_levels.id = pm_types.pm_composition_level_id
        LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = pm_products.std_fruit_size_count_id
        LEFT JOIN basic_packs_standard_packs ON basic_packs_standard_packs.basic_pack_id = pm_products.basic_pack_id
        LEFT JOIN standard_pack_codes ON standard_pack_codes.id = basic_packs_standard_packs.standard_pack_id
        WHERE pm_boms_products.pm_bom_id = #{pm_bom_id}
        ORDER BY pm_composition_levels.composition_level
      SQL
      DB[query]
        .all
    end

    def sync_pm_boms # rubocop:disable Metrics/AbcSize
      pm_type_id = get_id(:pm_types, pm_type_code: AppConst::PM_TYPE_FRUIT)
      pm_composition_level_id = get(:pm_types, pm_type_id, :pm_composition_level_id)
      raise Crossbeams::InfoError, "Please define a PKG Type with a composition level for #{AppConst::PM_TYPE_FRUIT}" if pm_type_id.nil? || pm_composition_level_id.nil?

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

    def find_basic_pack_height(basic_pack_id)
      DB[:basic_pack_codes]
        .where(id: basic_pack_id)
        .get(:height_mm)
    end

    def resolve_pm_bom_clone_attrs(pm_bom_id)
      pm_bom = find_hash(:pm_boms, pm_bom_id)
      fruit_product = find_pm_bom_fruit_product(pm_bom_id)

      { pm_bom_id: pm_bom_id,
        gross_weight: pm_bom[:gross_weight],
        nett_weight: pm_bom[:nett_weight],
        fruit_product_id: fruit_product[:id],
        pm_subtype_id: fruit_product[:pm_subtype_id],
        uom_id: fruit_product[:uom_id],
        quantity: fruit_product[:quantity],
        fruit_count_product_ids: available_for_clone_fruit_count_products(pm_bom_id, fruit_product[:pm_subtype_id]) }
    end

    def find_pm_bom_fruit_product(pm_bom_id)
      DB[:pm_boms_products]
        .join(:pm_products, id: :pm_product_id)
        .join(:pm_subtypes, id: :pm_subtype_id)
        .where(pm_bom_id: pm_bom_id)
        .where(pm_type_id: get_id(:pm_types, pm_type_code: AppConst::PM_TYPE_FRUIT))
        .select(Sequel[:pm_boms_products][:id],
                :pm_subtype_id,
                :uom_id,
                :quantity)
        .first
    end

    def available_for_clone_fruit_count_products(pm_bom_id, pm_subtype_id)
      return nil if pm_subtype_id.nil_or_empty?

      DB[:pm_products]
        .where(pm_subtype_id: pm_subtype_id)
        .exclude(id: DB[:pm_boms_products]
                       .join(:pm_products, id: :pm_product_id)
                       .join(:pm_boms, id: Sequel[:pm_boms_products][:pm_bom_id])
                       .where(pm_subtype_id: pm_subtype_id)
                       .where(Sequel.like(:bom_code, "#{pm_bom_system_code(pm_bom_id, pm_subtype_id)}%"))
                       .distinct
                       .select_map(:pm_product_id))
        .select_map(:id)
    end

    def clone_bom_to_count(attrs, fruit_count_product_id)
      new_pm_bom_id = create(:pm_boms, { bom_code: 'TEST',
                                         gross_weight: attrs[:gross_weight],
                                         nett_weight: attrs[:nett_weight] })

      DB.execute(<<~SQL)
        INSERT INTO pm_boms_products (pm_product_id, pm_bom_id, uom_id, quantity)
        SELECT pm_product_id, #{new_pm_bom_id}, uom_id, quantity
        FROM pm_boms_products
        JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
        WHERE pm_bom_id = #{attrs[:pm_bom_id]}
        AND pm_subtype_id != #{attrs[:pm_subtype_id]}
        UNION ALL
        SELECT #{fruit_count_product_id}, #{new_pm_bom_id}, #{attrs[:uom_id]}, #{attrs[:quantity]};
      SQL

      system_code = pm_bom_system_code(new_pm_bom_id)
      update(:pm_boms, new_pm_bom_id, { bom_code: system_code, system_code: system_code })
    end
  end
end
