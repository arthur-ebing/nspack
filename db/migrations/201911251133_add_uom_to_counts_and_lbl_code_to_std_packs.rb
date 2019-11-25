Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      add_column :std_pack_label_code, String
    end

    alter_table(:std_fruit_size_counts) do
      add_foreign_key :uom_id, :uoms, type: :integer
    end

    unless ENV['RACK_ENV'] == 'test'
      # Insert the required lookup value - but ignore if it is already in place:
      run "INSERT INTO uoms (uom_type_id, uom_code) VALUES ((SELECT id FROM uom_types WHERE code = 'INVENTORY'), 'EACH') ON CONFLICT DO NOTHING;"

      run "UPDATE std_fruit_size_counts SET uom_id = (SELECT id FROM uoms WHERE uom_code = 'EACH' AND uom_type_id = (SELECT id FROM uom_types WHERE code = 'INVENTORY'));"
    end

    alter_table(:std_fruit_size_counts) do
      set_column_not_null :uom_id
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      drop_column :std_pack_label_code
    end

    alter_table(:std_fruit_size_counts) do
      drop_column :uom_id
    end
  end
end
