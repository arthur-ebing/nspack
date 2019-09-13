# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:product_setups) do
      add_foreign_key :grade_id, :grades, key: [:id]
      add_column :product_chars, String
    end
  end

  down do
    alter_table(:product_setups) do
      drop_column(:grade_id)
      drop_column(:product_chars)
    end
  end
end
