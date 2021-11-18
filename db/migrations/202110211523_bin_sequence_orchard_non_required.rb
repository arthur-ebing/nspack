Sequel.migration do
  up do
    alter_table(:bin_sequences) do
      set_column_allow_null :orchard_id
    end
  end
  down do
    alter_table(:bin_sequences) do
      set_column_not_null :orchard_id
    end
  end
end
