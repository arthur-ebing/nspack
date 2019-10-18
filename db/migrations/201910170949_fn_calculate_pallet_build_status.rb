Sequel.migration do
  up do
    # Function to calculate the build_status for a pallet.
    # Provide a pallet_id and pallet carton_quantity.

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_calculate_pallet_build_status(plt_carton_quantity decimal, cartons_per_pallet decimal)
        RETURNS text AS
      $BODY$
        DECLARE
        BEGIN
          RETURN CASE 
            WHEN plt_carton_quantity < cartons_per_pallet THEN
              'PARTIAL'
            WHEN plt_carton_quantity > cartons_per_pallet THEN
              'OVERFULL'
            ELSE
              'FULL'
            END;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_calculate_pallet_build_status(decimal, decimal)
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP FUNCTION public.fn_calculate_pallet_build_status(decimal, decimal);
    SQL
  end
end
