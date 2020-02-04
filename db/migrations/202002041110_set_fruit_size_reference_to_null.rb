
Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      set_column_allow_null :fruit_size_reference_id
    end
  end

  down do
    alter_table(:pallet_sequences) do
      set_column_not_null :fruit_size_reference_id
    end
  end
end
