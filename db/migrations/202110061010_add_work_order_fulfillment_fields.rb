Sequel.migration do
  up do
    alter_table(:work_order_items) do
      add_column :pallet_fulfillment_warning_level, Integer
    end
    run "UPDATE work_order_items SET pallet_fulfillment_warning_level = 2;"

    create_table(:wo_fulfillment_queue, ignore_index_errors: true) do
      primary_key :id
      Integer :work_order_item_id
    end

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_add_wo_item_to_fulfillment_queue()
        RETURNS trigger AS
      $BODY$
        BEGIN
          IF (NEW.work_order_item_id IS NOT NULL) THEN
            EXECUTE 'INSERT INTO wo_fulfillment_queue (work_order_item_id) VALUES($1);' USING NEW.work_order_item_id;
          END IF;

          RETURN NEW;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_add_wo_item_to_fulfillment_queue()
        OWNER TO postgres;

      CREATE TRIGGER pallet_sequences_wo_fulfillment_queue
      AFTER INSERT OR UPDATE
      ON public.pallet_sequences
      FOR EACH ROW
      EXECUTE PROCEDURE fn_add_wo_item_to_fulfillment_queue();

      -- ==========================================================================
      -- Function to calculate work_order_items pallets_outstanding
      -- ==========================================================================

      CREATE OR REPLACE FUNCTION public.fn_woi_pallets_outstanding(in_id integer)
      RETURNS integer AS
      $BODY$
       SELECT ((woi.carton_qty_required - woi.carton_qty_produced) / cpp.cartons_per_pallet)::integer AS pallets_outstanding
       FROM work_order_items woi
       JOIN product_setups ON product_setups.id = woi.product_setup_id
       JOIN cartons_per_pallet cpp ON cpp.id = product_setups.cartons_per_pallet_id
       WHERE woi.id = in_id
      $BODY$
      LANGUAGE sql VOLATILE
      COST 100;
      ALTER FUNCTION public.fn_woi_pallets_outstanding(integer)
      OWNER TO postgres;
    SQL
  end

  down do
    alter_table(:work_order_items) do
      drop_column :pallet_fulfillment_warning_level
    end

    drop_table(:wo_fulfillment_queue)

    run <<~SQL
      DROP TRIGGER pallet_sequences_wo_fulfillment_queue ON pallet_sequences;
      DROP FUNCTION public.fn_add_wo_item_to_fulfillment_queue();

      DROP FUNCTION public.fn_woi_pallets_outstanding(integer);
    SQL
  end
end
