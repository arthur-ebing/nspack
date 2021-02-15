Sequel.migration do
  up do
    run "
    CREATE OR REPLACE FUNCTION public.fn_packing_specification_code(in_id integer)
    RETURNS text AS
    $BODY$
     SELECT concat(fn_product_setup_code(product_setup_id), '_',
			  COALESCE(pm_boms.system_code, '*'), '_',
			  COALESCE(pm_marks.description, '*'), '_',
			  packing_specification_items.id)
     FROM packing_specification_items
     LEFT JOIN pm_boms ON pm_boms.id = packing_specification_items.pm_bom_id
     LEFT JOIN pm_marks ON pm_marks.id = packing_specification_items.pm_mark_id
     WHERE packing_specification_items.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_packing_specification_code(integer)
    OWNER TO postgres;"

  end

  down do
    run 'DROP FUNCTION public.fn_packing_specification_code(integer);'
  end
end
