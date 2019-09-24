Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION fn_production_run_code(in_id integer)
      RETURNS text AS
      $BODY$
        SELECT
          f.farm_code || '_' ||
          p.puc_code || '_' ||
          COALESCE(o.orchard_code, 'MIX') || '_' ||
          g.cultivar_group_code || '_' ||
          COALESCE(c.cultivar_name, 'MIX') || '_' ||
          pr.id::text AS production_run_code
        FROM production_runs pr
        JOIN farms f ON f.id = pr.farm_id
        JOIN pucs p ON p.id = pr.puc_id
        LEFT OUTER JOIN orchards o ON o.id = pr.orchard_id
        JOIN cultivar_groups g ON g.id = pr.cultivar_group_id
        LEFT OUTER JOIN cultivars c ON c.id = pr.cultivar_id
        WHERE pr.id = in_id
      $BODY$
      LANGUAGE sql VOLATILE
      COST 100;
      ALTER FUNCTION public.fn_production_run_code(integer)
      OWNER TO postgres;
    SQL
  end

  down do
    run 'DROP FUNCTION fn_production_run_code(integer);'
  end
end
