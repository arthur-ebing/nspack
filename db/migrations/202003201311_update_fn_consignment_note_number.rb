Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_consignment_note_number(
          in_id integer)
        RETURNS text AS
      $BODY$
          SELECT LPAD(in_id::text, 10, '0')
      $BODY$
        LANGUAGE sql IMMUTABLE;
      ALTER FUNCTION public.fn_consignment_note_number(integer)
        OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_consignment_note_number(
          in_id integer)
        RETURNS text AS
      $BODY$
          SELECT LPAD(in_id::text, 10, '0')
      $BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_consignment_note_number(integer)
        OWNER TO postgres;
    SQL
  end
end
