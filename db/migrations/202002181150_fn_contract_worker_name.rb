Sequel.migration do
  up do
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
      DROP FUNCTION public.fn_contract_worker_name(integer);
    SQL
  end
end




