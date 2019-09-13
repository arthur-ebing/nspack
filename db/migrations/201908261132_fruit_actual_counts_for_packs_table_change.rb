# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do

    alter_table(:fruit_actual_counts_for_packs) do
      drop_constraint(:fruit_actual_counts_for_packs_std_fruit_size_count_id_basic_key)
      drop_column(:size_count_variation)
      add_unique_constraint [:std_fruit_size_count_id, :basic_pack_code_id], name: :fruit_actual_counts_for_packs_idx
      drop_constraint(:fruit_actual_counts_for_packs_standard_pack_code_id_fkey)
      drop_column(:standard_pack_code_id)
      add_column :standard_pack_code_ids, 'integer[]'# , null: false
      add_column :size_reference_ids, 'integer[]' # , null: false
    end

    run "UPDATE fruit_actual_counts_for_packs SET standard_pack_code_ids = '{}', size_reference_ids = '{}' WHERE standard_pack_code_ids IS NULL;"
    alter_table(:fruit_actual_counts_for_packs) do
      set_column_not_null :standard_pack_code_ids
      set_column_not_null :size_reference_ids
    end
  end

  down do
    alter_table(:fruit_actual_counts_for_packs) do
      drop_column(:size_reference_ids)
      # drop_column(:fruit_actual_counts_for_packs_standard_pack_code_fkey)
      drop_column(:standard_pack_code_ids)
      add_foreign_key :standard_pack_code_id, :standard_pack_codes #, null: false, key: [:id]
      drop_constraint(:fruit_actual_counts_for_packs_idx)
      add_column(:size_count_variation, 'text')
      add_unique_constraint [:std_fruit_size_count_id, :basic_pack_code_id, :size_count_variation], name: :fruit_actual_counts_for_packs_std_fruit_size_count_id_basic_key
    end
  end
end
