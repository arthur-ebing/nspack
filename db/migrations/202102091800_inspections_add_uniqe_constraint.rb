Sequel.migration do
  up do
    alter_table(:inspections) do
      add_index [:pallet_id, :inspection_type_id], name: :inspection_unique_code, unique: true
    end

  end

  down do
    alter_table(:inspections) do
      drop_index [:pallet_id, :inspection_type_id], name: :inspection_unique_code
    end
  end
end