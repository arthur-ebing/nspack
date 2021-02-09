Sequel.migration do
  up do
    alter_table(:inspection_types) do
      add_column :applicable_grade_ids, 'integer[]'
      add_column :applies_to_all_grades, TrueClass, default: false
    end
  end

  down do
    alter_table(:inspection_types) do
      drop_column :applies_to_all_grades
      drop_column :applicable_grade_ids
    end
  end
end
