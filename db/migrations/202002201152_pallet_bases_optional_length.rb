
Sequel.migration do
  up do
    alter_table(:pallet_bases) do
      set_column_allow_null :length
      set_column_allow_null :width
      set_column_allow_null :cartons_per_layer
    end
  end

  down do
    alter_table(:pallet_bases) do
      set_column_not_null :length
      set_column_not_null :width
      set_column_not_null :cartons_per_layer
    end
  end
end
