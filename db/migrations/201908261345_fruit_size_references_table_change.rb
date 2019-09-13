
require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:fruit_size_references) do
      drop_constraint(:fruit_size_references_fruit_actual_counts_for_pack_id_size__key)
      add_unique_constraint [:size_reference], name: :fruit_size_references_idx
      drop_constraint(:fruit_size_references_fruit_actual_counts_for_pack_id_fkey)
      drop_column(:fruit_actual_counts_for_pack_id)
    end
  end

  down do
    alter_table(:fruit_size_references) do
      add_foreign_key :fruit_actual_counts_for_pack_id, :fruit_actual_counts_for_packs # , null: false, key: [:id]
      drop_constraint(:fruit_size_references_idx)
      add_unique_constraint [:fruit_actual_counts_for_pack_id, :size_reference], name: :fruit_size_references_fruit_actual_counts_for_pack_id_size__key
    end
  end
end
