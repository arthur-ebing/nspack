require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:bin_integration_queue, ignore_index_errors: true) do
      primary_key :id
      DateTime :created_at
      Integer :bin_id
      Integer :job_no
      Jsonb :bin_data
      Jsonb :error
    end

    run 'CREATE SEQUENCE doc_seqs_bin_integration_queue;'
    pgt_created_at(:bin_integration_queue,
                   :created_at,
                   function_name: :bin_integration_queue_set_created_at,
                   trigger_name: :set_created_at)
  end

  down do
    drop_trigger(:bin_integration_queue, :set_created_at)
    drop_function(:bin_integration_queue_set_created_at)
    drop_table(:bin_integration_queue)

    run 'DROP SEQUENCE doc_seqs_bin_integration_queue;'
  end
end
