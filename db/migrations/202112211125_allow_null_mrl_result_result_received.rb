Sequel.migration do
  up do
    alter_table(:mrl_results) do
      set_column_allow_null :result_received_at
    end
  end

  down do
    alter_table(:mrl_results) do
      set_column_not_null :result_received_at
    end
  end
end
