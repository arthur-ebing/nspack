Sequel.migration do
  up do
    # Function to calculate the SSCC check-digit for a pallet number.
    # Provide a string of 17 digits and it returns a string of 18 digits.

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_sscc_number_with_check_digit(base_no text)
        RETURNS text AS
      $BODY$
        DECLARE
          p_index INT;
          p_multiplier INT DEFAULT 3;
          p_sum INT DEFAULT 0;
        BEGIN
          p_index = LENGTH(base_no);
          WHILE p_index > 0 LOOP
            p_sum = p_sum + p_multiplier * substring(base_no, p_index, 1)::integer;
            p_multiplier = 4 - p_multiplier;
            p_index = p_index - 1;
          END LOOP;

          RETURN CASE p_sum % 10
            WHEN 0 THEN
              base_no || '0'
            ELSE
              base_no || (10 - p_sum % 10)::text
            END;
        END
      $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_sscc_number_with_check_digit(text)
        OWNER TO postgres;
    SQL

    # SQL to test this function:
    # --------------------------
    # SELECT pallet_number, substr(pallet_number, 1, 17) AS short,
    # fn_sscc_number_with_check_digit(substr(pallet_number, 1, 17)) AS new_no
    # FROM ( VALUES
    # ('600980218296370786'),
    # ('600980218299840507'),
    # ('600980218299852418'),
    # ('960091600167901210'),
    # ('960091600167902774'),
    # ('960091600167901753'),
    # ('600980218298851856')
    # ) AS t(pallet_number)
  end

  down do
    run <<~SQL
      DROP FUNCTION public.fn_sscc_number_with_check_digit();
    SQL
  end
end
