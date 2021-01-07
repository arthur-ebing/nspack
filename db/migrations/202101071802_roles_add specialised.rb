Sequel.migration do
  up do
    alter_table(:roles) do
      add_column :specialised, :boolean, default: false
    end
    run <<~SQL
      UPDATE roles SET specialised=TRUE WHERE name IN ('SUPPLIER', 'INSPECTOR');
    SQL

  end

  down do
    alter_table(:roles) do
      drop_column :specialised
    end
  end
end