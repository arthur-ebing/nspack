
Sequel.migration do
  up do
    alter_table(:orchards) do
      drop_index :orchard_code, name: :orchards_unique_code
      add_unique_constraint [:farm_id, :orchard_code], name: :farm_orchard_unique_code
    end
  end

  down do
    alter_table(:orchards) do
      drop_constraint [:farm_id, :orchard_code], name: :farm_orchard_unique_code
      add_index :orchard_code, name: :orchards_unique_code
    end
  end

end
