Sequel.migration do
  up do
    alter_table(:grades) do
      rename_column :is_rmt_grade, :rmt_grade
    end
  end

  down do
    alter_table(:grades) do
      rename_column :rmt_grade, :is_rmt_grade
    end
  end
end
