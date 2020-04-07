require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    create_table(:destination_regions_tm_groups, ignore_index_errors: true) do
      foreign_key :target_market_group_id, :target_market_groups, type: :integer, null: false
      foreign_key :destination_region_id, :destination_regions, type: :integer, null: false

      index [:target_market_group_id,:destination_region_id], name: :destination_regions_tm_groups_idx, unique: true
    end
  end

  down do
    drop_table(:destination_regions_tm_groups)
  end
end
