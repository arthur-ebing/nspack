Sequel.migration do
  up do
    alter_table(:vehicle_jobs) do
      set_column_allow_null :govt_inspection_sheet_id, true
    end
  end

  down do
    alter_table(:vehicle_jobs) do
      set_column_allow_null :govt_inspection_sheet_id, false
    end
  end
end