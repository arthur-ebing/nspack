Sequel.migration do
  up do
    run "
    CREATE OR REPLACE FUNCTION public.fn_work_order_item_code(in_id integer)
    RETURNS text AS
    $BODY$
     SELECT concat(fn_party_role_org_code(marketing_orders.customer_party_role_id), '_',
                   marketing_orders.order_number, '_',
                   'W', work_orders.id, '_',
                   work_orders.start_date, '_',
                   work_orders.end_date, '_',
                   work_order_items.carton_qty_required, '_',
                   work_order_items.carton_qty_produced)
     FROM work_order_items
     JOIN work_orders ON work_orders.id = work_order_items.work_order_id
     LEFT JOIN marketing_orders ON marketing_orders.id = work_orders.marketing_order_id
     WHERE work_order_items.id = in_id
    $BODY$
    LANGUAGE sql VOLATILE
    COST 100;
    ALTER FUNCTION public.fn_work_order_item_code(integer)
    OWNER TO postgres;"

  end

  down do
    run 'DROP FUNCTION public.fn_work_order_item_code(integer);'
  end
end
