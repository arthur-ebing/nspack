Sequel.migration do
  up do
    alter_table(:fruit_actual_counts_for_packs) do
      set_column_allow_null :size_reference_ids
    end
  end

  down do
    run "UPDATE fruit_actual_counts_for_packs SET size_reference_ids = '{}' WHERE size_reference_ids IS NULL;"
    alter_table(:fruit_actual_counts_for_packs) do
      set_column_not_null :size_reference_ids
    end
  end
end
