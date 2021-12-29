Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_foreign_key :actual_cold_treatment_id, :treatments, key: [:id]
      add_foreign_key :actual_ripeness_treatment_id, :treatments, key: [:id]
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :actual_cold_treatment_id
      drop_column :actual_ripeness_treatment_id
    end
  end
end