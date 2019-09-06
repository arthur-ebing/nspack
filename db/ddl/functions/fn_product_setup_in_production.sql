-- Function: public.fn_product_setup_in_production(integer)

-- DROP FUNCTION public.fn_product_setup_in_production(integer);

CREATE OR REPLACE FUNCTION public.fn_product_setup_in_production(in_id integer)
  RETURNS bool AS
$BODY$
  SELECT true AS in_production
  FROM product_setups ps
  JOIN product_setup_templates pst ON pst.id = ps.product_setup_template_id
  WHERE ps.id = in_id
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.fn_product_setup_in_production(integer)
  OWNER TO postgres;
