Sequel.migration do
  up do
    alter_table(:production_runs) do
      add_foreign_key :colour_percentage_id, :colour_percentages, key: [:id]
      add_foreign_key :actual_cold_treatment_id, :treatments, key: [:id]
      add_foreign_key :actual_ripeness_treatment_id, :treatments, key: [:id]
      add_foreign_key :rmt_code_id, :rmt_codes, key: [:id]
      add_foreign_key :rmt_size_id, :rmt_sizes, key: [:id]
    end
  end

  down do
    alter_table(:production_runs) do
      drop_column :colour_percentage_id
      drop_column :actual_cold_treatment_id
      drop_column :actual_ripeness_treatment_id
      drop_column :rmt_code_id
      drop_column :rmt_size_id
    end
  end
end