Sequel.migration do
  up do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_party_role_delivery_address(
        in_id integer)
          RETURNS text
          LANGUAGE 'sql'
          COST 100
          VOLATILE 
          
      AS $BODY$
        SELECT CONCAT_WS(' ', a.address_line_1, a.address_line_2, address_line_3, city, postal_code, country)
          FROM party_roles pr
          JOIN party_addresses pa ON pa.party_id = pr.party_id
          JOIN address_types at ON at.id = pa.address_type_id
          JOIN addresses a ON a.id = pa.address_id
          WHERE pr.id = in_id
            AND at.address_type = 'Delivery Address';
      $BODY$;

      ALTER FUNCTION public.fn_party_role_delivery_address(integer)
          OWNER TO postgres;
    SQL
  end

  down do
    drop_function(:fn_party_role_delivery_address, args: :integer)
  end
end
