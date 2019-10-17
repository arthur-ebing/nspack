Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_calc_age_days(in_id integer, date_from timestamp, date_to timestamp)
      RETURNS  double precision AS
      $BODY$
        SELECT ABS(date_part('epoch', date_from::timestamp - COALESCE(date_to::timestamp, current_timestamp)) / 86400)
        FROM pallets
        WHERE id = in_id
      $BODY$
      LANGUAGE sql VOLATILE
      COST 100;
      ALTER FUNCTION public.fn_calc_age_days(integer, timestamp, timestamp)
      OWNER TO postgres;
    SQL
  end

  down do
    run 'DROP FUNCTION public.fn_calc_age_days(integer, timestamp, timestamp);'
  end
end
