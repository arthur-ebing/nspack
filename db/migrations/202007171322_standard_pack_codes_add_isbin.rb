Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      add_column :is_bin, :boolean, default: false
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      drop_column :is_bin
    end
  end
end
