Sequel.migration do
  up do
    alter_table(:inspection_types) do
      add_column :applicable_marketing_org_party_role_ids, 'integer[]'
      add_column :applies_to_all_marketing_org_party_roles, TrueClass, default: false
    end
  end

  down do
    alter_table(:inspection_types) do
      drop_column :applies_to_all_marketing_org_party_roles
      drop_column :applicable_marketing_org_party_role_ids
    end
  end
end
