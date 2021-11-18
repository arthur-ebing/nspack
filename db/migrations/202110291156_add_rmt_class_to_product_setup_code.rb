Sequel.migration do
  up do
    # ---------------------------
    # product_setup_code function
    # ---------------------------
    run <<~SQL
    CREATE OR REPLACE FUNCTION public.fn_product_setup_code(in_id integer)
    RETURNS text AS
    $BODY$
     SELECT CASE WHEN COALESCE(ps_commodity.requires_standard_counts, commodities.requires_standard_counts) THEN
              concat(COALESCE(ps_commodity.code, commodities.code), '_',
                  ps_cultivar.cultivar_name, '_',
                  marketing_varieties.marketing_variety_code, '_',
                  grades.grade_code, '_',
                  rmt_classes.rmt_class_code, '_',
                  std_fruit_size_counts.size_count_value, '_',
                  fruit_actual_counts_for_packs.actual_count_for_pack, '_',
                  fruit_size_references.size_reference, '_',
                  basic_pack_codes.basic_pack_code, '_',
                  organizations.short_description, '_',
                  target_market_groups.target_market_group_name, '_',
                  target_markets.target_market_name, '_',
                  fn_party_role_name(ps.target_customer_party_role_id), '_',
                  marks.mark_code, '_',
                  inventory_codes.inventory_code, '_',
                  ps.sell_by_code, '_',
                  pallet_bases.pallet_base_code, '_',
                  pallet_stack_types.stack_height, '_',
                  cartons_per_pallet.cartons_per_pallet, '_',
                  ps.id
              )
        ELSE
        concat(COALESCE(ps_commodity.code, commodities.code), '_',
              ps_cultivar.cultivar_name, '_',
              marketing_varieties.marketing_variety_code, '_',
              grades.grade_code, '_',
              rmt_classes.rmt_class_code, '_',
              fruit_size_references.size_reference, '_',
              basic_pack_codes.basic_pack_code, '_',
              organizations.short_description, '_',
              target_market_groups.target_market_group_name, '_',
              target_markets.target_market_name, '_',
              fn_party_role_name(ps.target_customer_party_role_id), '_',
              marks.mark_code, '_',
              inventory_codes.inventory_code, '_',
              ps.sell_by_code, '_',
              pallet_bases.pallet_base_code, '_',
              pallet_stack_types.stack_height, '_',
              cartons_per_pallet.cartons_per_pallet, '_',
              ps.id
          )
        END AS product_code
    FROM product_setups ps
    JOIN product_setup_templates pst ON pst.id = ps.product_setup_template_id
    JOIN cultivar_groups ON cultivar_groups.id = pst.cultivar_group_id
    JOIN commodities ON commodities.id = cultivar_groups.commodity_id
    LEFT JOIN cultivars ps_cultivar ON ps_cultivar.cultivar_group_id = pst.cultivar_group_id AND ps_cultivar.id = pst.cultivar_id
    LEFT JOIN cultivar_groups ps_cultivar_groups ON ps_cultivar_groups.id = ps_cultivar.cultivar_group_id
    LEFT JOIN commodities ps_commodity ON ps_commodity.id = ps_cultivar_groups.commodity_id
    JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
    JOIN grades on grades.id = ps.grade_id
    LEFT JOIN rmt_classes on rmt_classes.id = ps.rmt_class_id
    LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
    LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
    LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
    JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
    JOIN party_roles ON party_roles.id = ps.marketing_org_party_role_id
    JOIN organizations ON organizations.id = party_roles.organization_id
    JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
    LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
    JOIN marks ON marks.id = ps.mark_id
    LEFT JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
    JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
    JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
    JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
    JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
    WHERE ps.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_product_setup_code(integer)
    OWNER TO postgres;
    SQL

    # ---------------------------
    # packing_specification_code function
    # ---------------------------
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_packing_specification_code(in_id integer)
      RETURNS text AS
      $BODY$
         SELECT CASE WHEN COALESCE(ps_commodity.requires_standard_counts, commodities.requires_standard_counts) THEN
                  concat(COALESCE(ps_commodity.code, commodities.code), '_',
                         ps_cultivar.cultivar_name, '_',
                         marketing_varieties.marketing_variety_code, '_',
                         grades.grade_code, '_',
                         rmt_classes.rmt_class_code, '_',
                         std_fruit_size_counts.size_count_value, '_',
                         fruit_actual_counts_for_packs.actual_count_for_pack, '_',
                         fruit_size_references.size_reference, '_',
                         basic_pack_codes.basic_pack_code, '_',
                         organizations.short_description, '_',
                         target_market_groups.target_market_group_name, '_',
                         target_markets.target_market_name, '_',
                         fn_party_role_name(ps.target_customer_party_role_id), '_',
                         marks.mark_code, '_',
                         inventory_codes.inventory_code, '_',
                         ps.sell_by_code, '_',
                         pallet_bases.pallet_base_code, '_',
                         pallet_stack_types.stack_height, '_',
                         cartons_per_pallet.cartons_per_pallet, '_',
                         ps.id, '_',
                         COALESCE(pm_boms.system_code, '*'), '_',
                         COALESCE(pm_marks.description, '*'), '_',
                         packing_specification_items.id
                  )
            ELSE
            concat(COALESCE(ps_commodity.code, commodities.code), '_',
                   ps_cultivar.cultivar_name, '_',
                   marketing_varieties.marketing_variety_code, '_',
                   grades.grade_code, '_',
                   rmt_classes.rmt_class_code, '_',
                   fruit_size_references.size_reference, '_',
                   basic_pack_codes.basic_pack_code, '_',
                   organizations.short_description, '_',
                   target_market_groups.target_market_group_name, '_',
                   target_markets.target_market_name, '_',
                   fn_party_role_name(ps.target_customer_party_role_id), '_',
                   marks.mark_code, '_',
                   inventory_codes.inventory_code, '_',
                   ps.sell_by_code, '_',
                   pallet_bases.pallet_base_code, '_',
                   pallet_stack_types.stack_height, '_',
                   cartons_per_pallet.cartons_per_pallet, '_',
                   ps.id, '_',
                   COALESCE(pm_boms.system_code, '*'), '_',
                   COALESCE(pm_marks.description, '*'), '_',
                   packing_specification_items.id
              )
            END AS product_code
        FROM packing_specification_items
        LEFT JOIN pm_boms ON pm_boms.id = packing_specification_items.pm_bom_id
        LEFT JOIN pm_marks ON pm_marks.id = packing_specification_items.pm_mark_id
        JOIN product_setups ps ON ps.id = packing_specification_items.product_setup_id
        JOIN product_setup_templates pst ON pst.id = ps.product_setup_template_id
        JOIN cultivar_groups ON cultivar_groups.id = pst.cultivar_group_id
        JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        LEFT JOIN cultivars ps_cultivar ON ps_cultivar.cultivar_group_id = pst.cultivar_group_id AND ps_cultivar.id = pst.cultivar_id
        LEFT JOIN cultivar_groups ps_cultivar_groups ON ps_cultivar_groups.id = ps_cultivar.cultivar_group_id
        LEFT JOIN commodities ps_commodity ON ps_commodity.id = ps_cultivar_groups.commodity_id
        JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
        JOIN grades on grades.id = ps.grade_id
        LEFT JOIN rmt_classes on rmt_classes.id = ps.rmt_class_id
        LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
        JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
        JOIN party_roles ON party_roles.id = ps.marketing_org_party_role_id
        JOIN organizations ON organizations.id = party_roles.organization_id
        JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
        LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
        JOIN marks ON marks.id = ps.mark_id
        LEFT JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
        JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
        JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
        JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
        JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
        WHERE packing_specification_items.id = in_id
      $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_packing_specification_code(integer)
    OWNER TO postgres;
    SQL
  end
  down do
    # ---------------------------
    # product_setup_code function
    # ---------------------------
    run <<~SQL
    CREATE OR REPLACE FUNCTION public.fn_product_setup_code(in_id integer)
    RETURNS text AS
    $BODY$
     SELECT CASE WHEN COALESCE(ps_commodity.requires_standard_counts, commodities.requires_standard_counts) THEN
              concat(COALESCE(ps_commodity.code, commodities.code), '_',
                  ps_cultivar.cultivar_name, '_',
                  marketing_varieties.marketing_variety_code, '_',
                  grades.grade_code, '_',
                  std_fruit_size_counts.size_count_value, '_',
                  fruit_actual_counts_for_packs.actual_count_for_pack, '_',
                  fruit_size_references.size_reference, '_',
                  basic_pack_codes.basic_pack_code, '_',
                  organizations.short_description, '_',
                  target_market_groups.target_market_group_name, '_',
                  target_markets.target_market_name, '_',
                  fn_party_role_name(ps.target_customer_party_role_id), '_',
                  marks.mark_code, '_',
                  inventory_codes.inventory_code, '_',
                  ps.sell_by_code, '_',
                  pallet_bases.pallet_base_code, '_',
                  pallet_stack_types.stack_height, '_',
                  cartons_per_pallet.cartons_per_pallet, '_',
                  ps.id
              )
        ELSE
        concat(COALESCE(ps_commodity.code, commodities.code), '_',
              ps_cultivar.cultivar_name, '_',
              marketing_varieties.marketing_variety_code, '_',
              grades.grade_code, '_',
              fruit_size_references.size_reference, '_',
              basic_pack_codes.basic_pack_code, '_',
              organizations.short_description, '_',
              target_market_groups.target_market_group_name, '_',
              target_markets.target_market_name, '_',
              fn_party_role_name(ps.target_customer_party_role_id), '_',
              marks.mark_code, '_',
              inventory_codes.inventory_code, '_',
              ps.sell_by_code, '_',
              pallet_bases.pallet_base_code, '_',
              pallet_stack_types.stack_height, '_',
              cartons_per_pallet.cartons_per_pallet, '_',
              ps.id
          )
        END AS product_code
    FROM product_setups ps
    JOIN product_setup_templates pst ON pst.id = ps.product_setup_template_id
    JOIN cultivar_groups ON cultivar_groups.id = pst.cultivar_group_id
    JOIN commodities ON commodities.id = cultivar_groups.commodity_id
    LEFT JOIN cultivars ps_cultivar ON ps_cultivar.cultivar_group_id = pst.cultivar_group_id AND ps_cultivar.id = pst.cultivar_id
    LEFT JOIN cultivar_groups ps_cultivar_groups ON ps_cultivar_groups.id = ps_cultivar.cultivar_group_id
    LEFT JOIN commodities ps_commodity ON ps_commodity.id = ps_cultivar_groups.commodity_id
    JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
    JOIN grades on grades.id = ps.grade_id
    LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
    LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
    LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
    JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
    JOIN party_roles ON party_roles.id = ps.marketing_org_party_role_id
    JOIN organizations ON organizations.id = party_roles.organization_id
    JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
    LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
    JOIN marks ON marks.id = ps.mark_id
    LEFT JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
    JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
    JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
    JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
    JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
    WHERE ps.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_product_setup_code(integer)
    OWNER TO postgres;
    SQL

    # ---------------------------
    # packing_specification_code function
    # ---------------------------
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_packing_specification_code(in_id integer)
      RETURNS text AS
      $BODY$
         SELECT CASE WHEN COALESCE(ps_commodity.requires_standard_counts, commodities.requires_standard_counts) THEN
                  concat(COALESCE(ps_commodity.code, commodities.code), '_',
                         ps_cultivar.cultivar_name, '_',
                         marketing_varieties.marketing_variety_code, '_',
                         grades.grade_code, '_',
                         std_fruit_size_counts.size_count_value, '_',
                         fruit_actual_counts_for_packs.actual_count_for_pack, '_',
                         fruit_size_references.size_reference, '_',
                         basic_pack_codes.basic_pack_code, '_',
                         organizations.short_description, '_',
                         target_market_groups.target_market_group_name, '_',
                         target_markets.target_market_name, '_',
                         fn_party_role_name(ps.target_customer_party_role_id), '_',
                         marks.mark_code, '_',
                         inventory_codes.inventory_code, '_',
                         ps.sell_by_code, '_',
                         pallet_bases.pallet_base_code, '_',
                         pallet_stack_types.stack_height, '_',
                         cartons_per_pallet.cartons_per_pallet, '_',
                         ps.id, '_',
                         COALESCE(pm_boms.system_code, '*'), '_',
                         COALESCE(pm_marks.description, '*'), '_',
                         packing_specification_items.id
                  )
            ELSE
            concat(COALESCE(ps_commodity.code, commodities.code), '_',
                   ps_cultivar.cultivar_name, '_',
                   marketing_varieties.marketing_variety_code, '_',
                   grades.grade_code, '_',
                   fruit_size_references.size_reference, '_',
                   basic_pack_codes.basic_pack_code, '_',
                   organizations.short_description, '_',
                   target_market_groups.target_market_group_name, '_',
                   target_markets.target_market_name, '_',
                   fn_party_role_name(ps.target_customer_party_role_id), '_',
                   marks.mark_code, '_',
                   inventory_codes.inventory_code, '_',
                   ps.sell_by_code, '_',
                   pallet_bases.pallet_base_code, '_',
                   pallet_stack_types.stack_height, '_',
                   cartons_per_pallet.cartons_per_pallet, '_',
                   ps.id, '_',
                   COALESCE(pm_boms.system_code, '*'), '_',
                   COALESCE(pm_marks.description, '*'), '_',
                   packing_specification_items.id
              )
            END AS product_code
        FROM packing_specification_items
        LEFT JOIN pm_boms ON pm_boms.id = packing_specification_items.pm_bom_id
        LEFT JOIN pm_marks ON pm_marks.id = packing_specification_items.pm_mark_id
        JOIN product_setups ps ON ps.id = packing_specification_items.product_setup_id
        JOIN product_setup_templates pst ON pst.id = ps.product_setup_template_id
        JOIN cultivar_groups ON cultivar_groups.id = pst.cultivar_group_id
        JOIN commodities ON commodities.id = cultivar_groups.commodity_id
        LEFT JOIN cultivars ps_cultivar ON ps_cultivar.cultivar_group_id = pst.cultivar_group_id AND ps_cultivar.id = pst.cultivar_id
        LEFT JOIN cultivar_groups ps_cultivar_groups ON ps_cultivar_groups.id = ps_cultivar.cultivar_group_id
        LEFT JOIN commodities ps_commodity ON ps_commodity.id = ps_cultivar_groups.commodity_id
        JOIN marketing_varieties ON marketing_varieties.id = ps.marketing_variety_id
        JOIN grades on grades.id = ps.grade_id
        LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = ps.std_fruit_size_count_id
        LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = ps.fruit_actual_counts_for_pack_id
        LEFT JOIN fruit_size_references ON fruit_size_references.id = ps.fruit_size_reference_id
        JOIN basic_pack_codes ON basic_pack_codes.id = ps.basic_pack_code_id
        JOIN party_roles ON party_roles.id = ps.marketing_org_party_role_id
        JOIN organizations ON organizations.id = party_roles.organization_id
        JOIN target_market_groups ON target_market_groups.id = ps.packed_tm_group_id
        LEFT JOIN target_markets ON target_markets.id = ps.target_market_id
        JOIN marks ON marks.id = ps.mark_id
        LEFT JOIN inventory_codes ON inventory_codes.id = ps.inventory_code_id
        JOIN pallet_formats ON pallet_formats.id = ps.pallet_format_id
        JOIN pallet_bases ON pallet_bases.id = pallet_formats.pallet_base_id
        JOIN pallet_stack_types ON pallet_stack_types.id = pallet_formats.pallet_stack_type_id
        JOIN cartons_per_pallet ON cartons_per_pallet.id = ps.cartons_per_pallet_id
        WHERE packing_specification_items.id = in_id
      $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_packing_specification_code(integer)
    OWNER TO postgres;
    SQL
  end
end
