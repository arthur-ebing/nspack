Sequel.migration do
  up do
    alter_table(:presort_staging_runs) do
      set_column_allow_null :rmt_class_id
      set_column_allow_null :rmt_size_id
    end
  end

  down do
    alter_table(:presort_staging_runs) do
      set_column_not_null :rmt_class_id
      set_column_not_null :rmt_size_id
    end
  end
end
