Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_pallet_verification_failed(in_id integer)
      RETURNS bool AS
      $BODY$
        SELECT EXISTS(
          SELECT id
          FROM pallet_sequences
          WHERE pallet_id = in_id
          AND verified
          AND NOT verification_passed)
      $BODY$
      LANGUAGE sql VOLATILE
      COST 100;
      ALTER FUNCTION public.fn_pallet_verification_failed(integer)
      OWNER TO postgres;
    SQL
  end

  down do
    run 'DROP FUNCTION public.fn_pallet_verification_failed(integer);'
  end
end
