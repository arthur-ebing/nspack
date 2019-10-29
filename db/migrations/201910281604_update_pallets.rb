Sequel.migration do
  up do
    extension :pg_triggers
    alter_table(:pallets) do
      add_foreign_key [:load_id], :loads, name: :pallets_load_id_fkey
    end
  end

  down do
    alter_table(:pallets) do
      drop_foreign_key [:load_id], name: :pallets_load_id_fkey
    end
  end
end




