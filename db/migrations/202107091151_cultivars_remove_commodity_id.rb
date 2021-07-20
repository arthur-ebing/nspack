Sequel.migration do
  up do
    alter_table(:cultivars) do
      drop_column :commodity_id
    end
  end
  down do
    alter_table(:cultivars) do
      add_foreign_key :commodity_id, :commodities, type: :integer
    end

    run "UPDATE cultivars SET commodity_id = subquery.commodity_id
         FROM (SELECT id, commodity_id FROM  cultivar_groups) AS subquery
         WHERE cultivar_group_id = subquery.id;"

    alter_table(:cultivars) do
      set_column_not_null :commodity_id
    end
  end
end
