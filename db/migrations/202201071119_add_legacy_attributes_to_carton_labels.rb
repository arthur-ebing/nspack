Sequel.migration do
  up do
    alter_table(:carton_labels) do
      add_foreign_key :actual_cold_treatment_id, :treatments, key: [:id]
      add_foreign_key :actual_ripeness_treatment_id, :treatments, key: [:id]
      add_foreign_key :rmt_code_id, :rmt_codes, key: [:id]
    end

    alter_table(:pallet_sequences) do
      add_foreign_key :actual_cold_treatment_id, :treatments, key: [:id]
      add_foreign_key :actual_ripeness_treatment_id, :treatments, key: [:id]
      add_foreign_key :rmt_code_id, :rmt_codes, key: [:id]
    end
  end

  down do
    alter_table(:carton_labels) do
      drop_column :actual_cold_treatment_id
      drop_column :actual_ripeness_treatment_id
      drop_column :rmt_code_id
    end

    alter_table(:pallet_sequences) do
      drop_column :actual_cold_treatment_id
      drop_column :actual_ripeness_treatment_id
      drop_column :rmt_code_id
    end
  end
end
