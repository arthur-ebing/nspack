Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_foreign_key [:production_run_tipped_id], :production_runs, name: :rmt_bins_production_run_tipped_id_fkey
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_foreign_key [:production_run_tipped_id], name: :rmt_bins_production_run_tipped_id_fkey
    end
  end
end
