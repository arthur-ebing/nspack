Sequel.migration do
  up do
    alter_table(:carton_labels) do
      add_foreign_key [:marketing_puc_id], :pucs, name: :carton_labels_marketing_puc_id_fkey
    end

    alter_table(:pallet_sequences) do
      add_foreign_key [:marketing_puc_id], :pucs, name: :pallet_sequences_marketing_puc_id_fkey
    end
  end

  down do
    alter_table(:carton_labels) do
      drop_foreign_key [:marketing_puc_id], name: :carton_labels_marketing_puc_id_fkey
    end

    alter_table(:pallet_sequences) do
      drop_foreign_key [:marketing_puc_id], name: :pallet_sequences_marketing_puc_id_fkey
    end
  end
end
