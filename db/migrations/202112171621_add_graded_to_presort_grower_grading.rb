Sequel.migration do
  up do
    alter_table(:presort_grower_grading_bins) do
      add_column :graded, TrueClass, default: false
      add_foreign_key :treatment_id, :treatments, key: [:id]
      add_column :rmt_bin_weight, :decimal
    end
  end

  down do
    alter_table(:presort_grower_grading_bins) do
      drop_column :graded
      drop_column :treatment_id
      drop_column :rmt_bin_weight
    end
  end
end
