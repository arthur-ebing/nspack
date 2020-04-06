Sequel.migration do
  up do
    alter_table(:shift_exceptions) do
      drop_index [:shift_id], name: :fki_shift_exceptions_shifts
    end
  end

  down do
    alter_table(:shift_exceptions) do
      add_index [:shift_id], name: :fki_shift_exceptions_shifts, unique: true
    end
  end
end
