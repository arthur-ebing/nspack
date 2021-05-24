Sequel.migration do
  up do
    run <<~SQL
      TRUNCATE payment_terms CASCADE
    SQL
    alter_table(:payment_terms) do
      drop_column :payment_term_type_id
      add_foreign_key :deal_type_id, :deal_types, type: :integer, null: false
      add_foreign_key :incoterm_id, :incoterms, type: :integer, null: false
    end
  end

  down do
    run <<~SQL
      TRUNCATE payment_terms CASCADE
    SQL
    alter_table(:payment_terms) do
      add_foreign_key :payment_term_type_id, :payment_term_types, type: :integer, null: false
      drop_column :deal_type_id
      drop_column :incoterm_id
    end
  end
end
