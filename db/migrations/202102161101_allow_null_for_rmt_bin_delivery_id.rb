Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      set_column_allow_null :rmt_delivery_id
    end
  end

  down do
    alter_table(:rmt_bins) do
      set_column_not_null :rmt_delivery_id
    end
  end
end
