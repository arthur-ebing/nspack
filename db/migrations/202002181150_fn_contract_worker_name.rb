Sequel.migration do
  up do
    run <<~SQL
      -- ==========================================================================
      -- Concat fields for contract worker name
      -- ==========================================================================
      CREATE OR REPLACE FUNCTION public.fn_contract_worker_name(in_id integer)
          RETURNS text AS
      $BODY$
        SELECT concat(
          (CASE WHEN contract_workers.title IS NOT NULL THEN (contract_workers.title || ' ') ELSE NULL END),
          (contract_workers.full_names || ' ' ||
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

  down do
    run <<~SQL
      DROP FUNCTION public.fn_contract_worker_name(integer);
    SQL
  end
end




