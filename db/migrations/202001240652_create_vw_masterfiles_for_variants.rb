Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE VIEW public.vw_masterfiles_for_variants AS 
        SELECT 'marks' AS masterfile_table, mark_code AS lookup_code, id FROM marks
        UNION ALL
        SELECT 'grades'AS masterfile_table, grade_code AS lookup_code, id FROM grades
        UNION ALL
        SELECT 'pucs'AS masterfile_table, puc_code AS lookup_code, id FROM pucs
        UNION ALL
        SELECT 'inventory_codes'AS masterfile_table, inventory_code AS lookup_code, id FROM inventory_codes
        UNION ALL
        SELECT 'standard_pack_codes'AS masterfile_table, standard_pack_code AS lookup_code, id FROM standard_pack_codes
        UNION ALL
        SELECT 'marketing_varieties'AS masterfile_table, marketing_variety_code AS lookup_code, id FROM marketing_varieties
        UNION ALL
        SELECT 'fruit_size_references'AS masterfile_table, size_reference AS lookup_code, id FROM fruit_size_references
        UNION ALL
        SELECT 'packed_tm_group'AS masterfile_table, target_market_group_name AS lookup_code, id FROM target_market_groups
        ORDER BY 1, 2;

      ALTER TABLE public.vw_masterfiles_for_variants
        OWNER TO postgres;
    SQL
  end

  down do
    run "DROP VIEW public.vw_masterfiles_for_variants;"
  end
end
