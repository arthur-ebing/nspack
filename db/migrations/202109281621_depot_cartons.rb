Sequel.migration do
  up do
    create_table(:depot_cartons, ignore_index_errors: true) do
      foreign_key :pallet_sequence_id, :pallet_sequences, type: :integer, null: false
      Bignum :depot_carton_number

      index [:pallet_sequence_id, :depot_carton_number], name: :depot_cartons_unique_code, unique: true
    end

    run 'CREATE SEQUENCE doc_seqs_depot_carton_number START 300000000000;'
  end

  down do
    drop_table(:depot_cartons)

    run 'DROP SEQUENCE doc_seqs_depot_carton_number;'
  end
end
