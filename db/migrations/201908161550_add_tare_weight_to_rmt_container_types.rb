Sequel.migration do
  up do
    alter_table(:rmt_container_types) do
      add_column :tare_weight, Numeric
    end
  end

  down do
    alter_table(:rmt_container_types) do
      drop_column :tare_weight
    end
  end
end