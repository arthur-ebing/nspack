Sequel.migration do
  up do
    alter_table(:pallet_formats) do
      add_column :bin, TrueClass, default: false
    end
  end

  down do
    alter_table(:pallet_formats) do
      drop_column :bin
    end
  end
end
