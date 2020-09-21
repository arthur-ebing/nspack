Sequel.migration do
  up do
    alter_table(:organizations) do
      add_column :company_reg_no, String
    end
  end

  down do
    alter_table(:organizations) do
      drop_column :company_reg_no
    end
  end
end
