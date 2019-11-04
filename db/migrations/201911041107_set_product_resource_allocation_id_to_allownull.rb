
require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:carton_labels) do
      set_column_allow_null :product_resource_allocation_id
    end
    alter_table(:cartons) do
      set_column_allow_null :product_resource_allocation_id
    end
    alter_table(:pallet_sequences) do
      set_column_allow_null :product_resource_allocation_id
    end
  end

  down do
    alter_table(:carton_labels) do
      set_column_not_null :product_resource_allocation_id
    end
    alter_table(:cartons) do
      set_column_not_null :product_resource_allocation_id
    end
    alter_table(:pallet_sequences) do
      set_column_not_null :product_resource_allocation_id
    end
  end
end
