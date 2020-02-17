Sequel.migration do
  up do
    alter_table(:inspectors) do
      add_unique_constraint [:inspector_party_role_id], name: :inspector_party_role_uniq
    end
  end

  down do
    alter_table(:inspectors) do
      drop_constraint(:inspector_party_role_uniq)
    end
  end
end

