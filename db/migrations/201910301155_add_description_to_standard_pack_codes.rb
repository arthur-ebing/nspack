Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      add_column :description, String
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      drop_column :description
    end
  end
end
