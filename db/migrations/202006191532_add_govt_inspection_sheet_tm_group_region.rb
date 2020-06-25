
Sequel.migration do
  up do
    alter_table(:govt_inspection_sheets) do
      add_foreign_key :packed_tm_group_id, :target_market_groups
      add_foreign_key :destination_region_id, :destination_regions
      set_column_allow_null :destination_country_id
    end

    run <<~SQL
      UPDATE govt_inspection_sheets
      SET destination_region_id = subquery.destination_region_id
      FROM (SELECT id, destination_region_id
            FROM destination_countries) AS subquery
      WHERE govt_inspection_sheets.destination_country_id = subquery.id;
    SQL

    alter_table(:govt_inspection_sheets) do
      set_column_not_null :destination_region_id
    end
  end

  down do
    alter_table(:govt_inspection_sheets) do
      drop_column :packed_tm_group_id
      drop_column :destination_region_id
    end
  end
end
