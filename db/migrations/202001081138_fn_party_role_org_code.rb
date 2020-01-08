# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_party_role_org_code(in_id integer)
        RETURNS text AS
      $BODY$
        SELECT COALESCE(o.short_description, p.first_name || ' ' || p.surname) AS party_name
        FROM party_roles pr
        LEFT OUTER JOIN organizations o ON o.id = pr.organization_id
        LEFT OUTER JOIN people p ON p.id = pr.person_id
        WHERE pr.id = in_id
      $BODY$
        LANGUAGE sql VOLATILE
        COST 100;
      ALTER FUNCTION public.fn_party_role_org_code(integer)
        OWNER TO postgres;
    SQL
  end

  down do
    run 'DROP FUNCTION public.fn_party_role_org_code(integer);'
  end
end
