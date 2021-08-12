Sequel.migration do
  up do
    alter_table(:titan_requests) do
      set_column_type :request_id, String
    end
  end

  down do
    run 'UPDATE titan_requests SET request_id = NULL;'

    alter_table(:titan_requests) do
      set_column_type :request_id, Integer
    end
  end
end
