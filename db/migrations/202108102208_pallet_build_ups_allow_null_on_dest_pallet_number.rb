Sequel.migration do
  up do
    alter_table(:pallet_buildups) do
      set_column_allow_null :destination_pallet_number
    end
  end

  down do
    alter_table(:pallet_buildups) do
      set_column_not_null :destination_pallet_number
    end
  end
end
