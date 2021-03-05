require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    run <<~SQL
        CREATE FUNCTION public.fn_pkg_mark( 
            in_id integer)
          RETURNS text AS
        $BODY$
          SELECT concat(marks.mark_code, '_', (array_to_string(packaging_marks, '_'))) AS pkg_mark
          FROM marks
          JOIN pm_marks ON pm_marks.mark_id = marks.id
          WHERE  pm_marks.id = in_id;
        $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
        ALTER FUNCTION public.fn_pkg_mark(integer)
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
        DROP FUNCTION public.fn_pkg_mark(integer);
    SQL
  end
end
