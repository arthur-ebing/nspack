Sequel.migration do
  up do
    run "
    CREATE OR REPLACE FUNCTION public.fn_product_setup_in_production(in_id integer)
    RETURNS bool AS
    $BODY$
      SELECT
          CASE WHEN bool_and((id % 2) = 0) THEN false
          ELSE true END
      FROM product_setups ps
      WHERE ps.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_product_setup_in_production(integer)
    OWNER TO postgres;"

  end

  down do
    run 'DROP FUNCTION public.fn_product_setup_in_production(integer);'
  end
end
