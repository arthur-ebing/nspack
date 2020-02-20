Sequel.migration do
  up do
    alter_table(:contract_workers) do
       add_foreign_key :personnel_identifier_id, :personnel_identifiers, type: :integer
       add_index :personnel_identifier_id, unique: true
    end

    alter_table(:carton_labels) do
       add_foreign_key :personnel_identifier_id, :personnel_identifiers, type: :integer
       add_foreign_key :contract_worker_id, :contract_workers, type: :integer
    end

    alter_table(:cartons) do
       add_foreign_key :personnel_identifier_id, :personnel_identifiers, type: :integer
       add_foreign_key :contract_worker_id, :contract_workers, type: :integer
    end

    alter_table(:pallet_sequences) do
       add_foreign_key :personnel_identifier_id, :personnel_identifiers, type: :integer
       add_foreign_key :contract_worker_id, :contract_workers, type: :integer
    end

    alter_table(:mes_modules) do
      add_column :bulk_registration_mode, TrueClass, default: false
    end
  end

  down do
    alter_table(:contract_workers) do
       drop_foreign_key :personnel_identifier_id
    end

    alter_table(:carton_labels) do
       drop_foreign_key :personnel_identifier_id
       drop_foreign_key :contract_worker_id
    end

    alter_table(:cartons) do
       drop_foreign_key :personnel_identifier_id
       drop_foreign_key :contract_worker_id
    end

    alter_table(:pallet_sequences) do
       drop_foreign_key :personnel_identifier_id
       drop_foreign_key :contract_worker_id
    end

    alter_table(:mes_modules) do
      drop_column :bulk_registration_mode
    end
  end
end
