Sequel.migration do
  up do
    alter_table(:shift_types) do
      add_column :starting_quarter, Integer, default: 0
      add_column :ending_quarter, Integer, default: 0

      drop_index [:plant_resource_id, :employment_type_id, :start_hour, :end_hour, :day_night_or_custom], name: :shift_types_all_round_unique
      add_index [:plant_resource_id, :employment_type_id, :start_hour, :end_hour, :day_night_or_custom, :starting_quarter, :ending_quarter], name: :shift_types_all_round_unique , unique: true
    end

    alter_table(:shifts) do
      add_foreign_key :foreman_party_role_id, :party_roles, key: [:id]
    end

    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_shift_type_code(in_id integer)
          RETURNS text AS
      $BODY$
        SELECT 
          CASE WHEN st.starting_quarter = 0 and st.ending_quarter = 0 THEN 
            concat_ws('_', (CASE WHEN prt.id IS NOT NULL THEN parent_pr.plant_resource_code ELSE NULL END),
                      pr.plant_resource_code, emp.employment_type_code, st.day_night_or_custom,
                      st.start_hour, st.end_hour) 
          ELSE 
            concat(concat_ws('_', (CASE WHEN prt.id IS NOT NULL THEN parent_pr.plant_resource_code ELSE NULL END),
                             pr.plant_resource_code, emp.employment_type_code, st.day_night_or_custom,
                             st.start_hour, st.end_hour), 
                  '(', st.starting_quarter,',', st.ending_quarter,')') 
          END AS shift_type_code
        FROM shift_types st
        LEFT OUTER JOIN plant_resources pr ON st.plant_resource_id = pr.id
        LEFT OUTER JOIN plant_resource_types prt ON pr.plant_resource_type_id = prt.id AND prt.plant_resource_type_code = 'LINE'
        LEFT OUTER JOIN tree_plant_resources ON pr.id = tree_plant_resources.descendant_plant_resource_id
        LEFT OUTER JOIN plant_resources parent_pr ON tree_plant_resources.ancestor_plant_resource_id = parent_pr.id
        JOIN plant_resource_types parent_prt ON parent_pr.plant_resource_type_id = parent_prt.id AND parent_prt.plant_resource_type_code = 'PACKHOUSE'
        LEFT OUTER JOIN employment_types emp ON emp.id = st.employment_type_id
        WHERE st.id = in_id;
      $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
      ALTER FUNCTION public.fn_shift_type_code(integer)
          OWNER TO postgres;
    SQL
  end

  down do
    run <<~SQL
      CREATE OR REPLACE FUNCTION public.fn_shift_type_code(in_id integer)
          RETURNS text AS
      $BODY$
        SELECT concat_ws('_', (CASE WHEN prt.id IS NOT NULL THEN parent_pr.plant_resource_code ELSE NULL END),
          pr.plant_resource_code, emp.employment_type_code, st.day_night_or_custom,
          st.start_hour, st.end_hour) AS shift_type_code
        FROM shift_types st
        LEFT OUTER JOIN plant_resources pr ON st.plant_resource_id = pr.id
        LEFT OUTER JOIN plant_resource_types prt ON pr.plant_resource_type_id = prt.id AND prt.plant_resource_type_code = 'LINE'
        LEFT OUTER JOIN tree_plant_resources ON pr.id = tree_plant_resources.descendant_plant_resource_id
        LEFT OUTER JOIN plant_resources parent_pr ON tree_plant_resources.ancestor_plant_resource_id = parent_pr.id
        JOIN plant_resource_types parent_prt ON parent_pr.plant_resource_type_id = parent_prt.id AND parent_prt.plant_resource_type_code = 'PACKHOUSE'
        LEFT OUTER JOIN employment_types emp ON emp.id = st.employment_type_id
        WHERE st.id = in_id;
      $BODY$
          LANGUAGE sql VOLATILE
          COST 100;
      ALTER FUNCTION public.fn_shift_type_code(integer)
          OWNER TO postgres;
    SQL

    alter_table(:shift_types) do
      drop_column :starting_quarter
      drop_column :ending_quarter

      add_index [:plant_resource_id, :employment_type_id, :start_hour, :end_hour, :day_night_or_custom], name: :shift_types_all_round_unique, unique: true
    end

    alter_table(:shifts) do
      drop_column :foreman_party_role_id
    end
  end
end
