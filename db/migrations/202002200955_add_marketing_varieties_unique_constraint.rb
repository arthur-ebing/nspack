
Sequel.migration do
  up do
    run <<~SQL
      DELETE FROM marketing_varieties_for_cultivars WHERE marketing_variety_id IN ( 
        SELECT id FROM (SELECT id, ROW_NUMBER() OVER( PARTITION BY marketing_variety_code ORDER BY  id ) AS row_num 
                        FROM marketing_varieties) t WHERE t.row_num > 1 
        );
      DELETE FROM marketing_varieties WHERE id IN (
        SELECT id FROM (SELECT id, ROW_NUMBER() OVER( PARTITION BY marketing_variety_code ORDER BY  id ) AS row_num 
                        FROM marketing_varieties) t WHERE t.row_num > 1 
        );
    SQL
    alter_table(:marketing_varieties) do
      add_unique_constraint [:marketing_variety_code], name: :marketing_variety_unique_code
    end
  end

  down do
    alter_table(:marketing_varieties) do
      drop_constraint :marketing_variety_unique_code
    end
  end
end
