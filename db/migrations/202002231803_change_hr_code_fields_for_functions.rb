Sequel.migration do
  up do
    run <<~SQL
      -- ==========================================================================
      -- Concat all shift type fields for code
      -- ==========================================================================
      CREATE OR REPLACE FUNCTION public.fn_shift_type_code(in_id integer)
          RETURNS text AS
      $BODY$
        SELECT concat_ws('_', (CASE WHEN prt.id IS NOT NULL THEN parent_pr.plant_resource_code ELSE NULL END),
          pr.plant_resource_code, emp.employment_type_code, st.day_night_or_custom,
          st.start_hour, st.end_hour) AS shift_type_code
        FROM shift_types st
        LEFT OUTER JOIN plant_resources pr ON st.plant_resource_id = pr.id
        LEFT OUTER JOIN plant_resource_types prt ON pr.plant_resource_type_id = prt.id AND prt.plant_resource_type_code = 'LINE'
        LEFT OUTER JOIN tree_plant_resources ON pr.id = tree_plant_resources.descendant_plant_resource_id
        LEFT OUTER JOIN plant_resources parent_pr ON tree_plant_resources.ancestor_plant_resource_id = parent_pr.id
        JOIN plant_resource_types parent_prt ON parent_pr.plant_resource_type_id = parent_prt.id AND parent_prt.plant_resource_type_code = 'PACKHOUSE'
        LEFT OUTER JOIN employment_types emp ON emp.id = st.employment_type_id
        WHERE st.id = in_id;
      $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
      ALTER FUNCTION public.fn_shift_type_code(integer)
          OWNER TO postgres;
    SQL

    run <<~SQL
      -- ==========================================================================
      -- Concat fields for contract worker name
      -- ==========================================================================
      CREATE OR REPLACE FUNCTION public.fn_contract_worker_name(in_id integer)
          RETURNS text AS
      $BODY$
        SELECT concat_ws(' ', cw.title, cw.first_name, cw.surname) AS contract_worker_name
        FROM contract_workers cw
        WHERE cw.id = in_id;
      $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
      ALTER FUNCTION public.fn_contract_worker_name(integer)
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      -- ==========================================================================
      -- Concat all shift type fields for code
      -- ==========================================================================
      CREATE OR REPLACE FUNCTION public.fn_shift_type_code(in_id integer)
          RETURNS text AS
      $BODY$
        SELECT concat(
          (CASE WHEN prt.id IS NOT NULL THEN (parent_pr.plant_resource_code || '_') ELSE NULL END),
          (pr.plant_resource_code || '_' ||
            emp.employment_type_code || '_' ||
            st.day_night_or_custom || '_' ||
            st.start_hour || '_' ||
            st.end_hour)) AS shift_type_code
        FROM shift_types st
        LEFT OUTER JOIN plant_resources pr ON st.plant_resource_id = pr.id
        LEFT OUTER JOIN plant_resource_types prt ON pr.plant_resource_type_id = prt.id AND prt.plant_resource_type_code = 'LINE'
        LEFT OUTER JOIN tree_plant_resources ON pr.id = tree_plant_resources.descendant_plant_resource_id
        LEFT OUTER JOIN plant_resources parent_pr ON tree_plant_resources.ancestor_plant_resource_id = parent_pr.id
        JOIN plant_resource_types parent_prt ON parent_pr.plant_resource_type_id = parent_prt.id AND parent_prt.plant_resource_type_code = 'PACKHOUSE'
        LEFT OUTER JOIN employment_types emp ON emp.id = st.employment_type_id
        WHERE st.id = in_id;
      $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
      ALTER FUNCTION public.fn_shift_type_code(integer)
          OWNER TO postgres;
      -- resource_code (ph)+ resource_code (line)+ employment_type_code + D_N_C + start_hour + end_hour (FUNCTION)SQL
    SQL

    run <<~SQL
      -- ==========================================================================
      -- Concat fields for contract worker name
      -- ==========================================================================
      CREATE OR REPLACE FUNCTION public.fn_contract_worker_name(in_id integer)
          RETURNS text AS
      $BODY$
        SELECT concat(
          (CASE WHEN contract_workers.title IS NOT NULL THEN (contract_workers.title || ' ') ELSE NULL END),
          (contract_workers.first_name || ' ' ||
            contract_workers.surname)) AS contract_worker_name
        FROM contract_workers
        WHERE contract_workers.id = in_id;
      $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
      ALTER FUNCTION public.fn_contract_worker_name(integer)
          OWNER TO postgres;
    SQL
  end
end
