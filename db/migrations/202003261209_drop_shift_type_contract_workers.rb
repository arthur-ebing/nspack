Sequel.migration do
  up do
    drop_table(:shift_types_contract_workers)
  end

  down do
    create_table(:shift_types_contract_workers, ignore_index_errors: true) do
      primary_key :id
      foreign_key :shift_type_id, :shift_types, null: false, key: [:id]
      foreign_key :contract_worker_id, :contract_workers, null: false, key: [:id]

      index [:shift_type_id], name: :fki_shift_type_contract_workers_shift_types
      index [:contract_worker_id], name: :fki_shift_type_contract_workers_contract_workers
    end
  end
end
