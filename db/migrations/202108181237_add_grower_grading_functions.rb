Sequel.migration do
  up do
    # --- fn_grading_rule_item_code
    run <<~SQL
    CREATE OR REPLACE FUNCTION public.fn_grading_rule_item_code(in_id integer)
    RETURNS text AS
    $BODY$
     SELECT CASE WHEN grower_grading_rules.rebin_rule THEN
       concat(commodities.code, '_',
              marketing_varieties.marketing_variety_code, '_',
              inspection_types.inspection_type_code, '_',
              rmt_classes.rmt_class_code, '_',
              rmt_sizes.size_code, '_',
              rule_items.id
            )
        ELSE
            concat(commodities.code, '_',
              marketing_varieties.marketing_variety_code, '_',
              grades.grade_code, '_',
              inspection_types.inspection_type_code, '_',
              rmt_classes.rmt_class_code, '_',
              fruit_actual_counts_for_packs.actual_count_for_pack, '_',
              std_fruit_size_counts.size_count_value, '_',
              fruit_size_references.size_reference, '_',
              rule_items.id
            )
        END AS rule_item_code
    FROM grower_grading_rule_items rule_items
    JOIN grower_grading_rules ON grower_grading_rules.id = rule_items.grower_grading_rule_id
    JOIN commodities ON commodities.id = rule_items.commodity_id
    JOIN marketing_varieties ON marketing_varieties.id = rule_items.marketing_variety_id
    LEFT JOIN grades ON grades.id = rule_items.grade_id
    LEFT JOIN inspection_types ON inspection_types.id = rule_items.inspection_type_id
    LEFT JOIN rmt_classes ON rmt_classes.id = rule_items.rmt_class_id
    LEFT JOIN rmt_sizes ON rmt_sizes.id = rule_items.rmt_size_id
    LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = rule_items.fruit_actual_counts_for_pack_id 
    LEFT JOIN fruit_size_references ON fruit_size_references.id = rule_items.fruit_size_reference_id
    LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = rule_items.std_fruit_size_count_id
    WHERE rule_items.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_grading_rule_item_code(integer)
    OWNER TO postgres;
    SQL

    # --- fn_grading_carton_code
    run <<~SQL
    CREATE OR REPLACE FUNCTION public.fn_grading_carton_code(in_id integer)
    RETURNS text AS
    $BODY$
     SELECT 
      concat(fn_party_role_name(grading_cartons.marketing_org_party_role_id), '_',
                marketing_varieties.marketing_variety_code, '_',
                target_market_groups.target_market_group_name, '_',
                target_markets.target_market_name, '_',
                fruit_actual_counts_for_packs.actual_count_for_pack, '_',
                std_fruit_size_counts.size_count_value, '_',
                fruit_size_references.size_reference, '_',
                grades.grade_code, '_',
                rmt_classes.rmt_class_code, '_',
                inventory_codes.inventory_code, '_',
                grading_cartons.id
              ) AS grading_carton_code
    FROM grower_grading_cartons grading_cartons
    JOIN marketing_varieties ON marketing_varieties.id = grading_cartons.marketing_variety_id
    JOIN target_market_groups ON target_market_groups.id = grading_cartons.packed_tm_group_id
    LEFT JOIN target_markets ON target_markets.id = grading_cartons.target_market_id
    LEFT JOIN std_fruit_size_counts ON std_fruit_size_counts.id = grading_cartons.std_fruit_size_count_id 
    LEFT JOIN fruit_actual_counts_for_packs ON fruit_actual_counts_for_packs.id = grading_cartons.fruit_actual_counts_for_pack_id 
    LEFT JOIN fruit_size_references ON fruit_size_references.id = grading_cartons.fruit_size_reference_id
    JOIN grades ON grades.id = grading_cartons.grade_id
    LEFT JOIN rmt_classes ON rmt_classes.id = grading_cartons.rmt_class_id
    LEFT JOIN inventory_codes ON inventory_codes.id = grading_cartons.inventory_code_id
    WHERE grading_cartons.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_grading_carton_code(integer)
    OWNER TO postgres;
    SQL

    # --- fn_grading_rebin_code
    run <<~SQL
    CREATE OR REPLACE FUNCTION public.fn_grading_rebin_code(in_id integer)
    RETURNS text AS
    $BODY$
     SELECT
       concat(rmt_classes.rmt_class_code, '_',
              rmt_sizes.size_code, '_',
              grading_rebins.id
            ) AS grading_rebin_code
    FROM grower_grading_rebins grading_rebins
    LEFT JOIN rmt_classes ON rmt_classes.id = grading_rebins.rmt_class_id
    LEFT JOIN rmt_sizes ON rmt_sizes.id = grading_rebins.rmt_size_id
    WHERE grading_rebins.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_grading_rebin_code(integer)
    OWNER TO postgres;
    SQL
  end
  down do
    run 'DROP FUNCTION public.fn_grading_rule_item_code(integer);'
    run 'DROP FUNCTION public.fn_grading_carton_code(integer);'
    run 'DROP FUNCTION public.fn_grading_rebin_code(integer);'
  end
end
