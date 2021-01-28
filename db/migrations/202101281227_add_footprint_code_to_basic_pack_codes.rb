Sequel.migration do
  up do
    alter_table(:basic_pack_codes) do
      add_column :footprint_code, String
    end
  end

  down do
    alter_table(:basic_pack_codes) do
      drop_column :footprint_code
    end
  end
end
