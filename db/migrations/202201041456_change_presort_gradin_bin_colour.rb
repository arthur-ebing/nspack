Sequel.migration do
  up do
    alter_table(:presort_grower_grading_bins) do
      add_foreign_key :colour_percentage_id, :colour_percentages, key: [:id]
      drop_column :treatment_id
    end
    run 'UPDATE presort_grower_grading_bins
          SET colour_percentage_id = ts.colour_percentage_id
          FROM (SELECT presort_grower_grading_bins.id, colour_percentages.id AS colour_percentage_id FROM colour_percentages
                JOIN presort_grower_grading_bins ON colour_percentages.colour_percentage = presort_grower_grading_bins.maf_colour
                JOIN presort_grower_grading_pools ON presort_grower_grading_pools.id = presort_grower_grading_bins.presort_grower_grading_pool_id
                WHERE colour_percentages.commodity_id = presort_grower_grading_pools.commodity_id
               ) ts
          WHERE presort_grower_grading_bins.id = ts.id;'
  end

  down do
    alter_table(:presort_grower_grading_bins) do
      add_foreign_key :treatment_id, :treatments, key: [:id]
      drop_column :colour_percentage_id
    end
    run 'UPDATE presort_grower_grading_bins
          SET treatment_id = ts.treatment_id
          FROM (SELECT presort_grower_grading_bins.id, treatments.id AS treatment_id FROM treatments
                JOIN presort_grower_grading_bins ON treatments.treatment_code = presort_grower_grading_bins.maf_colour
               ) ts
          WHERE presort_grower_grading_bins.id = ts.id;'
  end
end
