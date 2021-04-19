Sequel.migration do
  up do
    drop_table(:legacy_barcodes)

    create_table(:legacy_barcodes, ignore_index_errors: true) do
      foreign_key :carton_label_id, :carton_labels, type: :integer, null: false, unique: true
      String :legacy_carton_number, unique: true
    end
  end

  down do
    drop_table(:legacy_barcodes)

    create_table(:legacy_barcodes, ignore_index_errors: true) do
      foreign_key :carton_label_id, :carton_labels, type: :integer, null: false
      String :legacy_carton_number

      index [:carton_label_id, :legacy_carton_number], name: :legacy_carton_number_carton_label_idx, unique: true
    end
  end
end
