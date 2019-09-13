Sequel.migration do
  up do
    alter_table(:rmt_container_types) do
      add_column :rmt_inner_container_type_id, Integer
    end
  end

  down do
    alter_table(:rmt_container_types) do
      drop_column :rmt_inner_container_type_id
    end
  end
end
