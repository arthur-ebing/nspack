Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_product_setup_template_in_production(in_id integer)
      RETURNS bool AS
      $BODY$
        SELECT EXISTS(
          SELECT id
          FROM production_runs
          WHERE product_setup_template_id = in_id
          AND running)
      $BODY$
      LANGUAGE sql VOLATILE
      COST 100;
      ALTER FUNCTION public.fn_product_setup_template_in_production(integer)
      OWNER TO postgres;
    SQL

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_product_setup_in_production(in_id integer)
      RETURNS bool AS
      $BODY$
        SELECT EXISTS(
          SELECT a.id
          FROM product_resource_allocations a
          JOIN production_runs p ON p.id = a.production_run_id
          WHERE a.product_setup_id = in_id
          AND p.running)
      $BODY$
      LANGUAGE sql VOLATILE
      COST 100;
      ALTER FUNCTION public.fn_product_setup_in_production(integer)
      OWNER TO postgres;
    SQL
  end

  down do
    run 'DROP FUNCTION public.fn_product_setup_in_production(integer);'
    run 'DROP FUNCTION public.fn_product_setup_template_in_production(integer);'
  end
end
