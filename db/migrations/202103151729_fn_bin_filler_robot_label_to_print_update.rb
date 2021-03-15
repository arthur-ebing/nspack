require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    run <<~SQL
        DROP FUNCTION public.fn_bin_filler_robot_label_to_print(integer);
        CREATE FUNCTION public.fn_bin_filler_robot_label_to_print(in_id integer)
          RETURNS text AS
        $BODY$
          SELECT
          CASE
           WHEN
                (SELECT every(p.resource_properties ->> 'carton_equals_pallet'::text ='t'::text) AS carton_equals_pallet
                  FROM plant_resources p
                  JOIN plant_resource_types prt ON prt.id = p.plant_resource_type_id
                  JOIN tree_plant_resources tpr ON tpr.descendant_plant_resource_id = p.id
                  WHERE tpr.ancestor_plant_resource_id = in_id
                  AND prt.plant_resource_type_code =  'ROBOT_BUTTON') THEN 'Pallet'
           WHEN
               (SELECT every(p.resource_properties ->> 'carton_equals_pallet'::text ='f'::text) AS carton_equals_pallet
                  FROM plant_resources p
                  JOIN plant_resource_types prt ON prt.id = p.plant_resource_type_id
                  JOIN tree_plant_resources tpr ON tpr.descendant_plant_resource_id = p.id
                  WHERE tpr.ancestor_plant_resource_id = in_id
                  AND prt.plant_resource_type_code =  'ROBOT_BUTTON') THEN 'Carton'
           ELSE 'Mixed'::text  
           END;
        $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
        ALTER FUNCTION public.fn_bin_filler_robot_label_to_print(integer)
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
        DROP FUNCTION public.fn_bin_filler_robot_label_to_print(integer);
        CREATE FUNCTION public.fn_bin_filler_robot_label_to_print(in_id integer)
          RETURNS text AS
        $BODY$
          SELECT
          CASE
           WHEN
                (SELECT every(p.resource_properties ->> 'carton_equals_pallet'::text ='true'::text) AS carton_equals_pallet
                  FROM plant_resources p
                  JOIN plant_resource_types prt ON prt.id = p.plant_resource_type_id
                  JOIN tree_plant_resources tpr ON tpr.descendant_plant_resource_id = p.id
                  WHERE tpr.ancestor_plant_resource_id = in_id
                  AND prt.plant_resource_type_code =  'ROBOT_BUTTON') THEN 'Pallet'
           WHEN
               (SELECT every(p.resource_properties ->> 'carton_equals_pallet'::text ='false'::text) AS carton_equals_pallet
                  FROM plant_resources p
                  JOIN plant_resource_types prt ON prt.id = p.plant_resource_type_id
                  JOIN tree_plant_resources tpr ON tpr.descendant_plant_resource_id = p.id
                  WHERE tpr.ancestor_plant_resource_id = in_id
                  AND prt.plant_resource_type_code =  'ROBOT_BUTTON') THEN 'Carton'
           ELSE 'Mixed'::text  
           END;
        $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
        ALTER FUNCTION public.fn_bin_filler_robot_label_to_print(integer)
          OWNER TO postgres;
    SQL
  end
end
