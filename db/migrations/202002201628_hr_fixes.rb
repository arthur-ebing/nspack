Sequel.migration do
  up do
    alter_table(:employment_types) do
      rename_column :code, :employment_type_code
    end

    alter_table(:contract_types) do
      rename_column :code, :contract_type_code
    end

    alter_table(:contract_workers) do
      add_foreign_key :shift_type_id, :shift_types, null: true, key: [:id]
      rename_column :full_names, :first_name
      set_column_type :start_date, :date
      set_column_type :end_date, :date
    end

    alter_table(:shifts) do
      add_column :start_date, :date
      drop_index [:shift_type_id], name: :fki_shifts_shift_types
      add_index [:shift_type_id, :start_date], name: :fki_shifts_shift_types_start_dates, unique: true
    end
  end

  down do
    alter_table(:shifts) do
      drop_index [:shift_type_id, :start_date], name: :fki_shifts_shift_types_start_dates
      drop_column :start_date
      add_index [:shift_type_id], name: :fki_shifts_shift_types, unique: true
    end

    alter_table(:employment_types) do
      rename_column :employment_type_code, :code
    end

    alter_table(:contract_types) do
      rename_column :contract_type_code, :code
    end

    alter_table(:contract_workers) do
      drop_column :shift_type_id
      rename_column :first_name, :full_names
      set_column_type :start_date, DateTime
      set_column_type :end_date, DateTime
    end
  end
end
