-- Function: public.fn_product_setup_code(integer)

-- DROP FUNCTION public.fn_product_setup_code(integer);

CREATE OR REPLACE FUNCTION public.fn_product_setup_code(in_id integer)
  RETURNS text AS
$BODY$
  SELECT concat(ps.id, '_', ps.product_setup_template_id ) AS product_code
  FROM product_setups ps
  JOIN product_setup_templates pst ON pst.id = ps.product_setup_template_id
  WHERE ps.id = in_id
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION public.fn_product_setup_code(integer)
  OWNER TO postgres;
