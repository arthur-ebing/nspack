Sequel.migration do
  up do
    alter_table(:basic_pack_codes) do
      add_column :bin, TrueClass, default: false
    end
  end

  down do
    alter_table(:basic_pack_codes) do
      drop_column :bin
    end
  end
end
