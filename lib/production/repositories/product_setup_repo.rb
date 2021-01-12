# frozen_string_literal: true

module ProductionApp
  class ProductSetupRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    build_for_select :product_setup_templates,
                     label: :template_name,
                     value: :id,
                     order_by: :template_name
    build_inactive_select :product_setup_templates,
                          label: :template_name,
                          value: :id,
                          order_by: :template_name

    build_for_select :product_setups,
                     label: :client_size_reference,
                     value: :id,
                     order_by: :client_size_reference
    build_inactive_select :product_setups,
                          label: :client_size_reference,
                          value: :id,
                          order_by: :client_size_reference

    crud_calls_for :product_setup_templates, name: :product_setup_template, wrapper: ProductSetupTemplate
    crud_calls_for :product_setups, name: :product_setup, wrapper: ProductSetup

    def find_product_setup_template(id)
      hash = find_with_association(:product_setup_templates,
                                   id,
                                   parent_tables: [{ parent_table: :cultivar_groups,
                                                     columns: [:cultivar_group_code],
                                                     flatten_columns: { cultivar_group_code: :cultivar_group_code } },
                                                   { parent_table: :cultivars,
                                                     columns: [:cultivar_name],
                                                     flatten_columns: { cultivar_name: :cultivar_name } },
                                                   { parent_table: :plant_resources,
                                                     columns: [:plant_resource_code],
                                                     foreign_key: :packhouse_resource_id,
                                                     flatten_columns: { plant_resource_code: :packhouse_resource_code } },
                                                   { parent_table: :plant_resources,
                                                     columns: [:plant_resource_code],
                                                     foreign_key: :production_line_id,
                                                     flatten_columns: { plant_resource_code: :production_line_code } },
                                                   { parent_table: :season_groups,
                                                     columns: [:season_group_code],
                                                     flatten_columns: { season_group_code: :season_group_code } },
                                                   { parent_table: :seasons,
                                                     columns: [:season_code],
                                                     flatten_columns: { season_code: :season_code } }])
      return nil if hash.nil?

      ProductSetupTemplate.new(hash)
    end

    def find_product_setup(id)
      hash = DB["SELECT product_setups.* ,cultivar_groups.commodity_id, pallet_formats.pallet_base_id, pallet_formats.pallet_stack_type_id,
                 pm_subtypes.pm_type_id, pm_products.pm_subtype_id, pm_boms.description, pm_boms.erp_bom_code,
                 fn_product_setup_code(product_setups.id) AS product_setup_code, fn_product_setup_in_production(product_setups.id) AS in_production
                 FROM product_setups
                 JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
                 JOIN cultivar_groups ON cultivar_groups.id = product_setup_templates.cultivar_group_id
                 LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = product_setups.std_fruit_size_count_id
                 JOIN pallet_formats ON pallet_formats.id = product_setups.pallet_format_id
                 LEFT JOIN pm_boms ON pm_boms.id = product_setups.pm_bom_id
                 LEFT JOIN pm_boms_products ON pm_boms_products.pm_bom_id = product_setups.pm_bom_id
                 LEFT JOIN pm_products ON pm_products.id = pm_boms_products.pm_product_id
                 LEFT JOIN pm_subtypes ON pm_subtypes.id = pm_products.pm_subtype_id
                 LEFT JOIN treatments ON treatments.id = ANY (product_setups.treatment_ids)
                 WHERE product_setups.id = ?", id].first
      return nil if hash.nil?

      ProductSetup.new(hash)
    end

    def for_select_plant_resources(plant_resource_type_code)
      DB[:plant_resources]
        .join(:plant_resource_types, id: :plant_resource_type_id)
        .where(plant_resource_type_code: plant_resource_type_code)
        .select(
          Sequel[:plant_resources][:id],
          :plant_resource_code
        ).map { |r| [r[:plant_resource_code], r[:id]] }
    end

    def for_select_packhouse_lines(packhouse_id)  # rubocop:disable Metrics/AbcSize
      DB[:plant_resources]
        .join(:tree_plant_resources, descendant_plant_resource_id: :id)
        .join(:plant_resource_types, id: Sequel[:plant_resources][:plant_resource_type_id])
        .where(ancestor_plant_resource_id: packhouse_id)
        .where(plant_resource_type_code: Crossbeams::Config::ResourceDefinitions::LINE)
        .where { path_length.> 0 } # rubocop:disable Style/NumericPredicate
        .select(
          Sequel[:plant_resources][:id],
          :plant_resource_code
        ).map { |r| [r[:plant_resource_code], r[:id]] }
    end

    def for_select_template_cultivar_commodities(cultivar_group_id, cultivar_id)  # rubocop:disable Metrics/AbcSize
      DB[:product_setup_templates]
        .join(:cultivar_groups, id: :cultivar_group_id)
        .join(:cultivars, cultivar_group_id: :id)
        .join(:commodities, id: :commodity_id)
        .where(Sequel[:product_setup_templates][:cultivar_group_id] => cultivar_group_id)
        .where(Sequel[:product_setup_templates][:cultivar_id] => cultivar_id)
        .distinct(Sequel[:commodities][:code])
        .select(
          Sequel[:commodities][:id],
          Sequel[:commodities][:code]
        )
        .order(:code)
        .map { |r| [r[:code], r[:id]] }
    end

    def commodity_id(cultivar_group_id, cultivar_id)  # rubocop:disable Metrics/AbcSize
      DB[:product_setup_templates]
        .join(:cultivar_groups, id: :cultivar_group_id)
        .join(:cultivars, cultivar_group_id: :id)
        .join(:commodities, id: :commodity_id)
        .where(Sequel[:product_setup_templates][:cultivar_group_id] => cultivar_group_id)
        .where(Sequel[:product_setup_templates][:cultivar_id] => cultivar_id)
        .distinct(Sequel[:commodities][:code])
        .select(
          Sequel[:commodities][:id],
          Sequel[:commodities][:code]
        )
        .order(Sequel[:commodities][:code])
        .get(Sequel[:commodities][:id])
    end

    def for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id)  # rubocop:disable Metrics/AbcSize
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .join(:cultivar_groups, id: :cultivar_group_id)
        .join(:product_setup_templates, cultivar_group_id: :id)
        .where(Sequel[:product_setup_templates][:id] => product_setup_template_id)
        .where(Sequel[:cultivars][:commodity_id] => commodity_id)
        .distinct(Sequel[:marketing_varieties][:id])
        .select(
          Sequel[:marketing_varieties][:id],
          Sequel[:marketing_varieties][:marketing_variety_code]
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def find_treatment_codes(id)
      query = <<~SQL
        SELECT treatments.treatment_code
        FROM product_setups
        JOIN treatments ON treatments.id = ANY (product_setups.treatment_ids)
        WHERE product_setups.id = #{id}
      SQL
      DB[query].order(:treatment_code).select_map(:treatment_code)
    end

    def activate_product_setup_template(id)
      product_setup_ids = product_setup_template_product_setup_ids(id)
      unless product_setup_ids.empty?
        DB.execute(<<~SQL)
          UPDATE product_setups set active = true
          WHERE product_setup_template_id IN (#{product_setup_ids.join(',')});
        SQL
      end

      DB.execute(<<~SQL)
        UPDATE product_setup_templates set active = true
                WHERE product_setup_templates.id = #{id};
      SQL
    end

    def deactivate_product_setup_template(id)
      product_setup_ids = product_setup_template_product_setup_ids(id)
      unless product_setup_ids.empty?
        DB.execute(<<~SQL)
          UPDATE product_setups set active = false
          WHERE product_setup_template_id IN (#{product_setup_ids.join(',')});
        SQL
      end
      deactivate(:product_setup_templates, id)
    end

    def activate_product_setup(id)
      DB.execute(<<~SQL)
        UPDATE product_setups set active = true
        WHERE product_setups.id = #{id};
      SQL
    end

    def deactivate_product_setup(id)
      deactivate(:product_setups, id)
    end

    def clone_product_setup_template(id, product_setup_template_id)
      product_setup_ids = product_setup_template_product_setup_ids(id)
      return if product_setup_ids.empty?

      product_setup_ids.each do |product_setup_id|
        attrs = find_hash(:product_setups, product_setup_id).reject { |k, _| %i[id product_setup_template_id].include?(k) }
        attrs[:product_setup_template_id] = product_setup_template_id
        create(:product_setups, attrs)
      end
    end

    def clone_product_setup(id)
      attrs = find_hash(:product_setups, id).reject { |k, _| k == :id }
      create(:product_setups, attrs)
    end

    def delete_product_setup_template(id)
      DB[:product_setups].where(product_setup_template_id: id).delete
      DB[:product_setup_templates].where(id: id).delete
      { success: true }
    end

    def product_setup_template_product_setup_ids(product_setup_template_id)
      DB[:product_setups]
        .where(product_setup_template_id: product_setup_template_id)
        .select_map(:id)
    end

    def cultivar_group_id
      DB[:cultivar_groups]
        .select(
          Sequel[:cultivar_groups][:id],
          Sequel[:cultivar_groups][:cultivar_group_code]
        )
        .order(:cultivar_group_code)
        .first[:id]
    end

    def pm_boms_products(product_setup_id)
      pm_bom = find_product_setup(product_setup_id)
      MasterfilesApp::BomRepo.new.pm_bom_products(pm_bom.pm_bom_id) unless pm_bom.nil?
    end

    def product_setup_in_production?(id)
      DB[Sequel.function(:fn_product_setup_in_production, id)].single_value
    end

    def product_setup_template_in_production?(id)
      DB[Sequel.function(:fn_product_setup_template_in_production, id)].single_value
    end

    def disable_cultivar_fields(product_setup_template_id)
      referenced_by_closed_or_inspected_runs?(product_setup_template_id)
    end

    def referenced_by_closed_or_inspected_runs?(_id)
      # query = <<~SQL
      #   SELECT EXISTS(
      #     SELECT id from production_runs WHERE product_setup_template_id = ? AND is_closed
      #     UNION ALL
      #     SELECT id from production_runs WHERE product_setup_template_id = ? AND govt_inspection_id IS NOT NULL
      #   )
      # SQL
      # DB[query, id].single_value
      false
    end

    def invalidates_any_product_setups_marketing_varieties?(template_name, where_clause)
      query = <<~SQL
        SELECT EXISTS(
           SELECT product_setups.id FROM product_setups
           JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           WHERE product_setup_templates.template_name = '#{template_name}'
           AND marketing_variety_id NOT IN (
              SELECT DISTINCT marketing_varieties.id
              FROM marketing_varieties
              JOIN marketing_varieties_for_cultivars ON marketing_varieties_for_cultivars.marketing_variety_id = marketing_varieties.id
              JOIN cultivars ON cultivars.id = marketing_varieties_for_cultivars.cultivar_id
              JOIN cultivar_groups ON cultivar_groups.id = cultivars.cultivar_group_id
              JOIN product_setup_templates ON product_setup_templates.cultivar_group_id = cultivar_groups.id
              #{where_clause}
           )
        )
      SQL
      DB[query].single_value
    end

    def update_product_setup_template(id, attrs)
      # production_run_ids = product_setup_template_production_run_ids(id)
      # DB[:cartons].where(production_run_id: production_run_ids)
      #             .update(cultivar_id: attrs[:cultivar_id])
      # DB[:pallet_sequences].where(production_run_id: production_run_ids)
      #                      .update(cultivar_id: attrs[:cultivar_id])
      # DB[:bins].where(production_run_rebin_id: production_run_ids)
      #          .update(cultivar_id: attrs[:cultivar_id])
      # DB[:production_runs].where(product_setup_template_id: id)
      #                     .update(cultivar_id: attrs[:cultivar_id])
      update(:product_setup_templates, id, attrs)
    end

    def product_setup_template_production_run_ids(product_setup_template_id)
      DB[:production_runs]
        .where(product_setup_template_id: product_setup_template_id)
        .select_map(:id)
    end

    def actual_count_standard_pack_code_id(standard_pack_code_ids)
      DB[:standard_pack_codes].where(id: standard_pack_code_ids).get(:id)
    end

    def basic_pack_standard_pack_code_id(basic_pack_code_id)
      DB[:standard_pack_codes]
        .join(:basic_pack_codes, basic_pack_code: :standard_pack_code)
        .where(Sequel[:basic_pack_codes][:id] => basic_pack_code_id)
        .get(Sequel[:standard_pack_codes][:id])
    end

    def find_gtin_code_for_update(instance)
      gtin_id = get_gtin_id(resolve_gtin_attrs(instance))
      find_gtin_code(gtin_id)
    end

    def resolve_gtin_attrs(attrs)
      std_fruit_size_count_id = attrs[:std_fruit_size_count_id].nil_or_empty? ? find_setup_std_fruit_size_count_id(attrs[:fruit_size_reference_id], attrs[:fruit_actual_counts_for_pack_id]) : attrs[:std_fruit_size_count_id]
      commodity_id = attrs[:commodity_id].nil_or_empty? ? find_size_count_commodity(std_fruit_size_count_id) : attrs[:commodity_id]
      attrs = attrs.slice(:marketing_variety_id,
                          :marketing_org_party_role_id,
                          :standard_pack_code_id,
                          :mark_id,
                          :grade_id,
                          :inventory_code_id,
                          :packed_tm_group_id)
      attrs[:std_fruit_size_count_id] = std_fruit_size_count_id
      attrs[:commodity_id] = commodity_id
      attrs
    end

    def find_setup_std_fruit_size_count_id(fruit_size_reference_id, fruit_actual_counts_for_pack_id)
      query = <<~SQL
        SELECT std_fruit_size_count_id
        FROM fruit_actual_counts_for_packs
        WHERE id = #{fruit_actual_counts_for_pack_id}
        AND #{fruit_size_reference_id} = ANY (size_reference_ids)
      SQL
      DB[query].single_value
    end

    def find_size_count_commodity(std_fruit_size_count_id)
      DB[:std_fruit_size_counts]
        .where(id: std_fruit_size_count_id)
        .get(:commodity_id)
    end

    def get_gtin_id(attrs)
      DB[:gtins]
        .where(attrs)
        .where(Sequel.lit('? between date_to and date_from', Time.now))
        .get(:id)
    end

    def find_gtin_code(id)
      DB[:gtins].where(id: id).get(:gtin_code)
    end
  end
end
