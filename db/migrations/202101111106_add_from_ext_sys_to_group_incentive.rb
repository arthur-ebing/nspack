Sequel.migration do
  up do
    alter_table(:group_incentives) do
      add_column :from_external_system, :boolean, default: false
    end
  end

  down do
    alter_table(:group_incentives) do
      drop_column :from_external_system
    end
  end
end
