Sequel.migration do
  up do
    alter_table(:packing_specification_items) do
      add_column :legacy_data, :jsonb
    end
  end

  down do
    alter_table(:packing_specification_items) do
      drop_column :legacy_data
    end
  end
end
