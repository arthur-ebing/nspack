Sequel.migration do
  up do
    alter_table(:presort_grower_grading_pools) do
      drop_column :track_slms_indicator_code
      add_column :rmt_code_ids, 'integer[]'
    end
    run 'UPDATE presort_grower_grading_pools
         SET rmt_code_ids = ts.rmt_bin_ids
         FROM (SELECT rmt_bins.presort_tip_lot_number,
                      array(SELECT DISTINCT a.rmt_code_id
                            FROM rmt_bins a
                            WHERE a.presort_tip_lot_number = rmt_bins.presort_tip_lot_number) AS rmt_bin_ids
               FROM rmt_bins) ts
         WHERE presort_grower_grading_pools.maf_lot_number = ts.presort_tip_lot_number;'
  end

  down do
    alter_table(:presort_grower_grading_pools) do
      add_column :track_slms_indicator_code, String
      drop_column :rmt_code_ids
    end
  end
end
