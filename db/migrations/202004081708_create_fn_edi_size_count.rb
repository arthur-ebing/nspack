Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_edi_size_count(
          in_pack_use_ref boolean,
          in_commodity_use_ref boolean,
          in_edi_out_code text,
          in_size_ref text,
          in_actual_count integer)
        RETURNS text AS
      $BODY$
          SELECT CASE WHEN in_pack_use_ref THEN
                   COALESCE(in_edi_out_code, in_size_ref, in_actual_count::text)
                 WHEN in_commodity_use_ref THEN
                   COALESCE(in_edi_out_code, in_size_ref, in_actual_count::text)
                 ELSE
                   COALESCE(in_actual_count::text, in_edi_out_code, in_size_ref)
                 END;
      $BODY$
        LANGUAGE sql IMMUTABLE;
      ALTER FUNCTION public.fn_edi_size_count(boolean, boolean, text, text, integer)
        OWNER TO postgres;

      COMMENT ON FUNCTION fn_edi_size_count(boolean, boolean, text, text, integer)
      IS 'This function can be tested with this query (the last character of each column is the expected value):
        (Change the repeated quotes to single quotes first)
        SELECT fn_edi_size_count(false, false, ''A'', ''B'', 9) AS ff_9,
               fn_edi_size_count(false, false, ''A'', ''B'', NULL) AS ff_a,
               fn_edi_size_count(false, false, NULL, ''B'', NULL) AS ff_b,
               fn_edi_size_count(true, false, NULL, NULL, NULL) AS ff_n,
               fn_edi_size_count(true, false, ''A'', ''B'', 9) AS tf_a,
               fn_edi_size_count(true, false, NULL, ''B'', 9) AS tf_b,
               fn_edi_size_count(true, false, NULL, NULL, 9) AS tf_9,
               fn_edi_size_count(true, false, NULL, NULL, NULL) AS tf_n,
               fn_edi_size_count(true, true, ''A'', ''B'', 9) AS tt_a,
               fn_edi_size_count(true, true, NULL, ''B'', 9) AS tt_b,
               fn_edi_size_count(true, true, NULL, NULL, 9) AS tt_9,
               fn_edi_size_count(true, true, NULL, NULL, NULL) AS tt_n,
               fn_edi_size_count(false, true, ''A'', ''B'', 9) AS ft_a,
               fn_edi_size_count(false, true, NULL, ''B'', 9) AS ft_b,
               fn_edi_size_count(false, true, NULL, NULL, 9) AS ft_9,
               fn_edi_size_count(false, true, NULL, NULL, NULL) AS ft_n;';
    SQL
  end

  down do
    run <<~SQL
      DROP FUNCTION public.fn_edi_size_count(boolean, boolean, text, text, integer);
    SQL
  end
end
