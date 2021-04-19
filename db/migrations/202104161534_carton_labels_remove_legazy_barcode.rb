Sequel.migration do
  up do
    alter_table(:carton_labels) do
      drop_column :legacy_carton_number
    end

    create_table(:legacy_barcodes, ignore_index_errors: true) do
      foreign_key :carton_label_id, :carton_labels, type: :integer, null: false
      String :legacy_carton_number

      index [:carton_label_id, :legacy_carton_number], name: :legacy_carton_number_carton_label_idx, unique: true
    end
  end

  down do
    drop_table(:legacy_barcodes)

    alter_table(:carton_labels) do
      add_column :legacy_carton_number, String
    end
  end
end
