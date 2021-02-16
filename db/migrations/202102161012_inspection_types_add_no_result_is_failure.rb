Sequel.migration do
  up do
    alter_table(:inspection_types) do
      drop_column :applies_to_all_orchards
      drop_column :applicable_orchard_ids
      drop_column :applies_to_all_cultivars
      drop_column :applicable_cultivar_ids
      add_column :passed_default, TrueClass, default: false
      add_index [:inspection_type_code], name: :inspection_type_unique_code, unique: true
    end
  end

  down do
    alter_table(:inspection_types) do
      drop_column :passed_default
      add_column :applicable_cultivar_ids, 'integer[]'
      add_column :applies_to_all_cultivars, TrueClass, default: false
      add_column :applicable_orchard_ids, 'integer[]'
      add_column :applies_to_all_orchards, TrueClass, default: false
      drop_index [:inspection_type_code], name: :inspection_type_unique_code
    end
  end
end
