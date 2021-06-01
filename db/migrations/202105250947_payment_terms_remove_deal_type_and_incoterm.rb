Sequel.migration do
  up do
    alter_table(:payment_terms) do
      drop_column :deal_type_id
      drop_column :incoterm_id
    end
  end

  down do
    alter_table(:payment_terms) do
      add_foreign_key :deal_type_id, :deal_types, type: :integer, null: false
      add_foreign_key :incoterm_id, :incoterms, type: :integer, null: false
    end
  end
end
