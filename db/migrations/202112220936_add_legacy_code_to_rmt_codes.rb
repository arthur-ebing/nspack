Sequel.migration do
  up do
    alter_table(:rmt_codes) do
      add_column :legacy_code, String
    end
  end

  down do
    alter_table(:rmt_codes) do
      drop_column :legacy_code
    end
  end
end