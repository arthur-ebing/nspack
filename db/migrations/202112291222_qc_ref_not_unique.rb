Sequel.migration do
  up do
    alter_table(:qc_samples) do
      drop_constraint :qc_samples_ref_number_key
    end
  end

  down do
    alter_table(:qc_samples) do
      add_unique_constraint :ref_number
    end
  end
end
