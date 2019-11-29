Sequel.migration do
  up do
    create_table(:production_run_stats_queue, ignore_index_errors: true) do
      primary_key :id
      Integer :production_run_id
    end
  end

  down do
    drop_table(:production_run_stats_queue)
  end
end
