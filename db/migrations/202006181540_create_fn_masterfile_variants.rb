Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_masterfile_variants(
          in_table text,
          in_id integer)
        RETURNS text[] AS
      $BODY$
        SELECT array_agg(masterfile_variants.variant_code order by masterfile_variants.variant_code) filter (where masterfile_variants.variant_code is not null) AS variant_codes
        FROM masterfile_variants
        WHERE masterfile_table = in_table
          AND masterfile_id = in_id
      $BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_masterfile_variants(text, integer)
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      DROP FUNCTION public.fn_masterfile_variants(text, integer);
    SQL
  end
end
