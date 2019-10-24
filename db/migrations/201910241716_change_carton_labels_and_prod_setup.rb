# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:product_setups) do
      set_column_not_null :inventory_code_id
    end

    alter_table(:carton_labels) do
      rename_column :production_line_resource_id, :production_line_id
      set_column_allow_null :fruit_size_reference_id
      add_column :sell_by_code, String
      add_column :grade_id, Integer
      add_column :product_chars, String
      add_column :pallet_label_name, String
    end

    alter_table(:cartons) do
      rename_column :production_line_resource_id, :production_line_id
      set_column_allow_null :fruit_size_reference_id
      add_column :sell_by_code, String
      add_column :grade_id, Integer
      add_column :product_chars, String
      add_column :pallet_label_name, String
    end

    alter_table(:pallet_sequences) do
      rename_column :production_line_resource_id, :production_line_id
    end

    alter_table(:product_setup_templates) do
      rename_column :production_line_resource_id, :production_line_id
    end
  end

  down do
    alter_table(:product_setups) do
      set_column_allow_null :inventory_code_id
    end

    alter_table(:carton_labels) do
      rename_column :production_line_id, :production_line_resource_id
      set_column_not_null :fruit_size_reference_id
      drop_column :sell_by_code
      drop_column :grade_id
      drop_column :product_chars
      drop_column :pallet_label_name
    end

    alter_table(:cartons) do
      rename_column :production_line_id, :production_line_resource_id
      set_column_not_null :fruit_size_reference_id
      drop_column :sell_by_code
      drop_column :grade_id
      drop_column :product_chars
      drop_column :pallet_label_name
    end

    alter_table(:pallet_sequences) do
      rename_column :production_line_id, :production_line_resource_id
    end

    alter_table(:product_setup_templates) do
      rename_column :production_line_id, :production_line_resource_id
    end
  end
end
