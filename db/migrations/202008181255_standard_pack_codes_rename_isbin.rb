Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      rename_column :is_bin, :bin
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      rename_column :bin, :is_bin
    end
  end
end
