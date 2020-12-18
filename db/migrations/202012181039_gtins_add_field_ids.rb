Sequel.migration do
  up do

    alter_table(:gtins) do
      add_column :commodity_id, Integer
      add_column :marketing_variety_id, Integer
      add_column :marketing_org_party_role_id, Integer
      add_column :standard_pack_code_id, Integer
      add_column :mark_id, Integer
      add_column :grade_id, Integer
      add_column :inventory_code_id, Integer
      add_column :packed_tm_group_id, Integer
      add_column :std_fruit_size_count_id, Integer
    end

  end

  down do
    alter_table(:gtins) do
      drop_column :commodity_id
      drop_column :marketing_variety_id
      drop_column :marketing_org_party_role_id
      drop_column :standard_pack_code_id
      drop_column :mark_id
      drop_column :grade_id
      drop_column :inventory_code_id
      drop_column :packed_tm_group_id
      drop_column :std_fruit_size_count_id
    end
  end
end
