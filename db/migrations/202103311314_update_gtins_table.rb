Sequel.migration do
  up do
    alter_table(:gtins) do
      drop_column :target_market_code
      drop_column :packed_tm_group_id
      drop_column :std_fruit_size_count_id
      add_column :fruit_actual_counts_for_pack_id, Integer
      add_column :fruit_size_reference_id, Integer
    end
  end

  down do
    alter_table(:gtins) do
      add_column :target_market_code, String
      add_column :packed_tm_group_id, Integer
      add_column :std_fruit_size_count_id, Integer
      drop_column :fruit_actual_counts_for_pack_id
      drop_column :fruit_size_reference_id
    end
  end
end
