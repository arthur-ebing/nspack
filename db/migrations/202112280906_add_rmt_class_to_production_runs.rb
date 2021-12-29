Sequel.migration do
  up do
    alter_table(:production_runs) do
      add_foreign_key :rmt_class_id, :rmt_classes, key: [:id]
    end
  end

  down do
    alter_table(:production_runs) do
      drop_column :rmt_class_id
    end
  end
end