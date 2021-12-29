# frozen_string_literal: true

module ProductionApp
  class ProductSetupRepo < BaseRepo
    build_for_select :product_setup_templates,
                     label: :template_name,
                     value: :id,
                     order_by: :template_name
    build_inactive_select :product_setup_templates,
                          label: :template_name,
                          value: :id,
                          order_by: :template_name
    crud_calls_for :product_setup_templates, name: :product_setup_template
    crud_calls_for :product_setups, name: :product_setup, exclude: [:delete]

    def for_select_product_setups(where: {}, active: true)
      DB[:product_setups]
        .where(active: active)
        .where(where)
        .select(:id, Sequel.function(:fn_product_setup_code, :id))
        .map { |r| [r[:fn_product_setup_code], r[:id]] }
    end

    def for_select_inactive_product_setups(where: {})
      for_select_product_setups(where: where, active: false)
    end

    def find_product_setup_template(id)
      find_with_association(
        :product_setup_templates, id,
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
                          flatten_columns: { season_code: :season_code } }],
        wrapper: ProductSetupTemplate
      )
    end

    def find_product_setup(id)
      hash = DB["SELECT product_setups.* ,cultivar_groups.commodity_id, pallet_formats.pallet_base_id, pallet_formats.pallet_stack_type_id,
                 fn_product_setup_code(product_setups.id) AS product_setup_code, fn_product_setup_in_production(product_setups.id) AS in_production,
                 product_setup_templates.template_name AS product_setup_template, product_setup_templates.cultivar_group_id,
                 product_setup_templates.cultivar_id, cultivar_groups.cultivar_group_code AS cultivar_group,
                 cultivars.cultivar_name AS cultivar, label_templates.label_template_name AS carton_template_name
                 FROM product_setups
                 JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
                 JOIN cultivar_groups ON cultivar_groups.id = product_setup_templates.cultivar_group_id
                 LEFT JOIN cultivars ON cultivars.id = product_setup_templates.cultivar_id
                 LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = product_setups.std_fruit_size_count_id
                 JOIN pallet_formats ON pallet_formats.id = product_setups.pallet_format_id
                 LEFT JOIN treatments ON treatments.id = ANY (product_setups.treatment_ids)
                 LEFT JOIN label_templates ON label_templates.id = product_setups.carton_label_template_id
                 WHERE product_setups.id = ?", id].first
      return nil if hash.nil?

      ProductSetupFlat.new(hash)
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

    def for_select_packhouse_lines(packhouse_id)
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

    def for_select_template_cultivar_commodities(cultivar_group_id, cultivar_id) # rubocop:disable Metrics/AbcSize
      DB[:product_setup_templates]
        .join(:cultivar_groups, id: :cultivar_group_id)
        .join(:commodities, id: Sequel[:cultivar_groups][:commodity_id])
        .left_join(:cultivars, id: Sequel[:product_setup_templates][:cultivar_id])
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

    def get_commodity_id(cultivar_group_id, cultivar_id) # rubocop:disable Metrics/AbcSize
      DB[:product_setup_templates]
        .join(:cultivar_groups, id: :cultivar_group_id)
        .join(:commodities, id: Sequel[:cultivar_groups][:commodity_id])
        .left_join(:cultivars, id: Sequel[:product_setup_templates][:cultivar_id])
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

    def for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id, cultivar_id = nil) # rubocop:disable Metrics/AbcSize
      ds = DB[:marketing_varieties]
           .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
           .join(:cultivars, id: :cultivar_id)
           .join(:cultivar_groups, id: :cultivar_group_id)
           .join(:product_setup_templates, cultivar_group_id: :id)
           .where(Sequel[:product_setup_templates][:id] => product_setup_template_id)
           .where(Sequel[:cultivar_groups][:commodity_id] => commodity_id)
      ds = ds.where(Sequel[:cultivars][:id] => cultivar_id) unless cultivar_id.nil_or_empty?
      ds.distinct(Sequel[:marketing_varieties][:id])
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
        WHERE product_setups.id = ?
      SQL
      DB[query, id].order(:treatment_code).select_map(:treatment_code)
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

    def delete_product_setup(id)
      DB[:packing_specification_items].where(product_setup_id: id).delete
      delete(:product_setups, id)
    end

    def clone_product_setup_template(id, args)
      product_setup_ids = product_setup_template_product_setup_ids(id)
      return if product_setup_ids.empty?

      product_setup_ids.each do |product_setup_id|
        attrs = find_hash(:product_setups, product_setup_id).reject { |k, _| %i[id product_setup_template_id marketing_variety_id].include?(k) }
        create(:product_setups, attrs.merge(args))
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

    def product_setup_in_production?(id)
      DB[Sequel.function(:fn_product_setup_in_production, id)].single_value
    end

    def product_setup_template_in_production?(id)
      DB[Sequel.function(:fn_product_setup_template_in_production, id)].single_value
    end

    def invalidates_any_product_setups_marketing_varieties?(template_name, where_clause)
      query = <<~SQL
        SELECT EXISTS(
           SELECT product_setups.id FROM product_setups
           JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
           WHERE product_setup_templates.template_name = ?
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
      DB[query, template_name].single_value
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

    def check_weights_for_product_setup(product_setup_id)
      query = <<~SQL
        SELECT standard_product_weights.min_gross_weight, standard_product_weights.max_gross_weight,
        standard_pack_codes.standard_pack_code AS pack_code, commodities.code AS commodity_code
        FROM product_setups
        JOIN product_setup_templates ON product_setup_templates.id = product_setups.product_setup_template_id
        JOIN cultivar_groups ON cultivar_groups.id = product_setup_templates.cultivar_group_id
        JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        JOIN standard_pack_codes ON standard_pack_codes.id = product_setups.standard_pack_code_id
        LEFT JOIN standard_product_weights ON standard_product_weights.commodity_id = cultivar_groups.commodity_id
          AND standard_product_weights.standard_pack_id = product_setups.standard_pack_code_id
        WHERE product_setups.id = ?
      SQL
      DB[query, product_setup_id].first
    end

    def resolve_gtin_attrs(attrs)
      std_fruit_size_count_id = attrs[:std_fruit_size_count_id].nil_or_empty? ? find_setup_std_fruit_size_count_id(attrs[:fruit_size_reference_id], attrs[:fruit_actual_counts_for_pack_id]) : attrs[:std_fruit_size_count_id]
      commodity_id = attrs[:commodity_id].nil_or_empty? ? find_size_count_commodity(std_fruit_size_count_id) : attrs[:commodity_id]
      fruit_size_reference_id = attrs[:fruit_size_reference_id]
      attrs = attrs.slice(:marketing_variety_id,
                          :marketing_org_party_role_id,
                          :standard_pack_code_id,
                          :mark_id,
                          :grade_id,
                          :inventory_code_id,
                          :fruit_actual_counts_for_pack_id)
      attrs[:commodity_id] = commodity_id
      attrs[:fruit_size_reference_id] = fruit_size_reference_id if attrs[:fruit_actual_counts_for_pack_id].nil_or_empty?
      attrs
    end

    def find_setup_std_fruit_size_count_id(fruit_size_reference_id, fruit_actual_counts_for_pack_id)
      return nil unless fruit_size_reference_id && fruit_actual_counts_for_pack_id

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
        .where(Sequel.lit('? between date_from and COALESCE(date_to::timestamp, current_timestamp)', Time.now)) # value BETWEEN low AND high
        .get(:id)
    end

    def find_gtin_code(id)
      DB[:gtins].where(id: id).get(:gtin_code)
    end

    def recalc_gtin_code?(attrs)
      recalc = AppConst::CR_PROD.use_gtins?
      gtin_fields = %i[std_fruit_size_count_id marketing_variety_id marketing_org_party_role_id standard_pack_code_id
                       mark_id grade_id inventory_code_id fruit_actual_counts_for_pack_id fruit_size_reference_id]
      recalc = false unless gtin_fields.any? { |k| attrs.key?(k) }
      recalc
    end

    def for_select_cultivar_group_marketing_varieties(cultivar_group_id)
      DB[:marketing_varieties]
        .join(:marketing_varieties_for_cultivars, marketing_variety_id: :id)
        .join(:cultivars, id: :cultivar_id)
        .join(:cultivar_groups, id: :cultivar_group_id)
        .where(Sequel[:cultivar_groups][:id] => cultivar_group_id)
        .distinct
        .select(
          Sequel[:marketing_varieties][:id],
          Sequel[:marketing_varieties][:marketing_variety_code]
        ).map { |r| [r[:marketing_variety_code], r[:id]] }
    end

    def find_template_marketing_variety(product_setup_template_id)
      DB[:product_setups]
        .where(product_setup_template_id: product_setup_template_id)
        .get(:marketing_variety_id)
    end

    def packing_specification_item_unit_pack_product(packing_specification_item_id) # rubocop:disable Metrics/AbcSize
      hash = DB[:packing_specification_items]
             .join(:pm_boms_products, pm_bom_id: :pm_bom_id)
             .join(:pm_products, id: :pm_product_id)
             .join(:pm_subtypes, id: :pm_subtype_id)
             .join(:pm_types, id: :pm_type_id)
             .where(Sequel[:packing_specification_items][:id] => packing_specification_item_id,
                    pm_composition_level_id: 2)
             .select(Sequel[:pm_products][:id],
                     Sequel[:pm_boms_products][:quantity]).first
      return "Product code and quantity not found for packing_specification_item_id: #{packing_specification_item_id}" if hash.nil_or_empty?

      quantity = hash[:quantity].to_i
      quantity = '*' if [0, 1].include? quantity
      code = get_kromco_mes_value(:pm_products, hash[:id], :product_code)

      "#{quantity}#{code}"
    end

    def packing_specification_item_unit_pack_product_for_seq(pm_bom_id) # rubocop:disable Metrics/AbcSize
      hash = DB[:pm_boms_products]
             .join(:pm_products, id: :pm_product_id)
             .join(:pm_subtypes, id: :pm_subtype_id)
             .join(:pm_types, id: :pm_type_id)
             .where(pm_bom_id: pm_bom_id,
                    pm_composition_level_id: 2)
             .select(Sequel[:pm_products][:id],
                     Sequel[:pm_boms_products][:quantity]).first
      return "Product code and quantity not found for pm_bom: #{pm_bom_id}" if hash.nil_or_empty?

      quantity = hash[:quantity].to_i
      quantity = '*' if [0, 1].include? quantity
      code = get_kromco_mes_value(:pm_products, hash[:id], :product_code)

      "#{quantity}#{code}"
    end

    def packing_specification_item_carton_pack_product(packing_specification_item_id) # rubocop:disable Metrics/AbcSize
      hash = DB[:packing_specification_items]
             .join(:pm_boms_products, pm_bom_id: :pm_bom_id)
             .join(:pm_products, id: :pm_product_id)
             .join(:basic_pack_codes, id: :basic_pack_id)
             .join(:pm_subtypes, id: Sequel[:pm_products][:pm_subtype_id])
             .join(:pm_types, id: :pm_type_id)
             .where(Sequel[:packing_specification_items][:id] => packing_specification_item_id,
                    pm_composition_level_id: 1)
             .select(
               Sequel[:pm_types][:short_code].as(:pm_type_short_code),
               Sequel[:basic_pack_codes][:footprint_code],
               Sequel[:pm_subtypes][:short_code].as(:pm_subtype_short_code),
               Sequel[:basic_pack_codes][:height_mm]
             ).first
      return nil if hash.nil?

      item_carton_pack_product_string(hash)
    end

    def packing_specification_item_carton_pack_product_for_seq(pm_bom_id) # rubocop:disable Metrics/AbcSize
      hash = DB[:pm_boms_products]
             .join(:pm_products, id: :pm_product_id)
             .join(:basic_pack_codes, id: :basic_pack_id)
             .join(:pm_subtypes, id: Sequel[:pm_products][:pm_subtype_id])
             .join(:pm_types, id: :pm_type_id)
             .where(pm_bom_id: pm_bom_id,
                    pm_composition_level_id: 1)
             .select(
               Sequel[:pm_types][:short_code].as(:pm_type_short_code),
               Sequel[:basic_pack_codes][:footprint_code],
               Sequel[:pm_subtypes][:short_code].as(:pm_subtype_short_code),
               Sequel[:basic_pack_codes][:height_mm]
             ).first
      return nil if hash.nil?

      item_carton_pack_product_string(hash)
    end

    def item_carton_pack_product_string(hash)
      unless hash[:height_mm] && hash[:footprint_code]
        mail = <<~STR
          Extended FG for packing specification item:#{packing_specification_item_id} could not be fetched.

          #{hash[:height_mm].nil? ? 'height_mm' : 'footprint_code'} is missing
        STR

        ErrorMailer.send_error_email(subject: 'EXT FG CODE INTEGRATION FAIL',
                                     message: mail,
                                     append_recipients: AppConst::LEGACY_SYSTEM_ERROR_RECIPIENTS)
        return mail
      end

      "#{hash[:pm_type_short_code]}#{hash[:footprint_code]}#{hash[:pm_subtype_short_code]}#{hash[:height_mm]}"
    end

    def prod_setup_organisation(prod_setup_id)
      id = DB[:product_setups]
           .join(:party_roles, id: :marketing_org_party_role_id)
           .where(Sequel[:product_setups][:id] => prod_setup_id)
           .get(:organization_id)
      get_kromco_mes_value(:organizations, id, :short_description)
    end

    def packing_specification_item_fg_marks(packing_specification_item_id)
      packaging_marks = DB[:packing_specification_items]
                        .join(:pm_marks, id: :pm_mark_id)
                        .where(Sequel[:packing_specification_items][:id] => packing_specification_item_id)
                        .get(:packaging_marks)
      return ['No packaging marks found'] unless packaging_marks

      translate_pm_marks(packaging_marks)
    end

    def translate_pm_marks(packaging_marks)
      marks = []
      packaging_marks.each do |inner_pm_mark_code|
        id = get_id(:inner_pm_marks, inner_pm_mark_code: inner_pm_mark_code)
        marks << get_kromco_mes_value(:inner_pm_marks, id, :inner_pm_mark_code)
      end
      marks
    end

    def cosmetic_code(packing_specification_item_id)
      fruit_mark = packing_specification_item_fg_marks(packing_specification_item_id).last
      return 'UL' if fruit_mark == 'NONE'

      'LB'
    end

    def cosmetic_code_for_seq(pm_mark_id)
      fruit_mark = (get(:pm_marks, pm_mark_id, :packaging_marks) || []).last
      return 'No packaging marks found' unless fruit_mark
      return 'UL' if translate_pm_marks(Array(fruit_mark)).first == 'NONE'

      'LB'
    end

    def get_kromco_mes_value(table_name, id, column)
      MasterfilesApp::GeneralRepo.new.get_transformation_or_value('Kromco MES', table_name, id, column)
    end

    def calculate_extended_fg_code(packing_specification_item_id, packaging_marks_join: '_') # rubocop:disable Metrics/AbcSize
      product_setup_id = get(:packing_specification_items, packing_specification_item_id, :product_setup_id)
      prod_setup = find_product_setup(product_setup_id).to_h

      fg_code_components = []
      fg_code_components << get_kromco_mes_value(:commodities, prod_setup[:commodity_id], :code)
      fg_code_components << get_kromco_mes_value(:marketing_varieties, prod_setup[:marketing_variety_id], :marketing_variety_code)
      fg_code_components << get_kromco_mes_value(:rmt_classes, prod_setup[:rmt_class_id], :rmt_class_code)
      fg_code_components << get_kromco_mes_value(:grades, prod_setup[:grade_id], :grade_code)
      fg_code_components << get_kromco_mes_value(:fruit_actual_counts_for_packs, prod_setup[:fruit_actual_counts_for_pack_id], :actual_count_for_pack)
      fg_code_components << get_kromco_mes_value(:basic_pack_codes, prod_setup[:basic_pack_code_id], :footprint_code)
      fg_code_components << cosmetic_code(packing_specification_item_id)
      fg_code_components << (get_kromco_mes_value(:fruit_size_references, prod_setup[:fruit_size_reference_id], :size_reference) || 'NOS')
      fg_code_components << packing_specification_item_unit_pack_product(packing_specification_item_id)
      carton_pack_product = packing_specification_item_carton_pack_product(packing_specification_item_id)
      return nil unless carton_pack_product

      fg_code_components << carton_pack_product
      fg_code_components << prod_setup_organisation(prod_setup[:id])
      fg_code_components << packing_specification_item_fg_marks(packing_specification_item_id).reverse.join(packaging_marks_join)
      fg_code_components.join('_')
    end

    def sequences_grouped_for_ext_fg(pallet_ids)
      query = <<~SQL
        SELECT
          cultivar_groups.commodity_id,
          marketing_variety_id,
          rmt_class_id,
          grade_id,
          fruit_actual_counts_for_pack_id,
          basic_pack_code_id,
          fruit_size_reference_id,
          pm_mark_id,
          pm_bom_id,
          party_roles.organization_id,
          ARRAY_AGG(pallet_sequences.id) AS ids
        FROM
          pallet_sequences
          JOIN cultivar_groups ON cultivar_groups.id = pallet_sequences.cultivar_group_id
          LEFT JOIN party_roles ON party_roles.id = pallet_sequences.marketing_org_party_role_id
          JOIN pallets ON pallets.id = pallet_sequences.pallet_id
        WHERE
          pallet_id IN ?
          AND NOT pallets.depot_pallet
        GROUP BY
          cultivar_groups.commodity_id,
          marketing_variety_id,
          rmt_class_id,
          grade_id,
          fruit_actual_counts_for_pack_id,
          basic_pack_code_id,
          fruit_size_reference_id,
          pm_mark_id,
          pm_bom_id,
          party_roles.organization_id
      SQL
      DB[query, Array(pallet_ids)].all
    end

    def calculate_extended_fg_code_from_sequences(seq, packaging_marks_join: '_') # rubocop:disable Metrics/AbcSize
      fg_code_components = []
      fg_code_components << get_kromco_mes_value(:commodities, seq[:commodity_id], :code)
      fg_code_components << get_kromco_mes_value(:marketing_varieties, seq[:marketing_variety_id], :marketing_variety_code)
      fg_code_components << get_kromco_mes_value(:rmt_classes, seq[:rmt_class_id], :rmt_class_code)
      fg_code_components << get_kromco_mes_value(:grades, seq[:grade_id], :grade_code)
      fg_code_components << get_kromco_mes_value(:fruit_actual_counts_for_packs, seq[:fruit_actual_counts_for_pack_id], :actual_count_for_pack)
      fg_code_components << get_kromco_mes_value(:basic_pack_codes, seq[:basic_pack_code_id], :footprint_code)
      fg_code_components << cosmetic_code_for_seq(seq[:pm_mark_id])
      fg_code_components << (get_kromco_mes_value(:fruit_size_references, seq[:fruit_size_reference_id], :size_reference) || 'NOS')
      fg_code_components << packing_specification_item_unit_pack_product_for_seq(seq[:pm_bom_id])
      carton_pack_product = packing_specification_item_carton_pack_product_for_seq(seq[:pm_bom_id])
      return nil unless carton_pack_product

      fg_code_components << carton_pack_product

      fg_code_components << get_kromco_mes_value(:organizations, seq[:organization_id], :short_description)
      marks_set = get(:pm_marks, seq[:pm_mark_id], :packaging_marks)
      marks_set = translate_pm_marks(marks_set || ['No packaging marks found'])
      fg_code_components << marks_set.reverse.join(packaging_marks_join)
      fg_code_components.join('_')
    end

    def look_for_existing_product_setup_id(res)
      args = res.to_h
      treatment_ids = args.delete(:treatment_ids)

      select_values(:product_setups, %i[id treatment_ids], args).each do |id, check_ids|
        return id if Array(check_ids).to_set == Array(treatment_ids).to_set
      end
      nil
    end

    def for_select_rmt_container_material_owners(where: {})
      DB[:rmt_container_material_owners]
        .join(:rmt_container_material_types, id: :rmt_container_material_type_id)
        .where(where)
        .distinct
        .select(Sequel[:rmt_container_material_owners][:id],
                :container_material_type_code,
                Sequel.function(:fn_party_role_name, :rmt_material_owner_party_role_id))
        .map { |rec| ["#{rec[:container_material_type_code]} - #{rec[:fn_party_role_name]}", rec[:id]] }
    end

    def rmt_container_material_owner_for(rmt_container_material_owner_id)
      query = <<~SQL
        SELECT CONCAT(container_material_type_code, ' - ', fn_party_role_name(rmt_material_owner_party_role_id))
        FROM rmt_container_material_owners
        JOIN rmt_container_material_types ON rmt_container_material_types.id = rmt_container_material_owners.rmt_container_material_type_id
        WHERE rmt_container_material_owners.id = ?
      SQL
      DB[query, rmt_container_material_owner_id].single_value
    end

    def requires_material_owner?(standard_pack_code_id, grade_id)
      # NOTE: This is set to true IF
      # AppConst::CR_RMT.use_bin_asset_control? rule is set AND
      # Standard pack is a bin AND Grade is an RMT grade.
      return false if standard_pack_code_id.nil_or_empty? || grade_id.nil_or_empty?

      require_owner = AppConst::CR_RMT.use_bin_asset_control?
      require_owner = false unless get(:standard_pack_codes, standard_pack_code_id, :bin)
      require_owner = false unless get(:grades, grade_id, :rmt_grade)
      require_owner
    end
  end
end
