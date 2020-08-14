Sequel.migration do
  up do
    alter_table(:grades) do
      add_column :is_rmt_grade, :boolean, default: false
    end
  end

  down do
    alter_table(:grades) do
      drop_column :is_rmt_grade
    end
  end
end
