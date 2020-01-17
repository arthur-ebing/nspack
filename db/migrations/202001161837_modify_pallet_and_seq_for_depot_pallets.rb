Sequel.migration do
  up do
    alter_table(:pallets) do
      set_column_allow_null :plt_packhouse_resource_id
      set_column_allow_null :plt_line_resource_id

      add_constraint(:depot_plt_ph_line_check) { Sequel.lit('depot_pallet OR (plt_packhouse_resource_id IS NOT NULL AND plt_line_resource_id IS NOT NULL)') }
    end

    alter_table(:pallet_sequences) do
      set_column_allow_null :production_run_id
      set_column_allow_null :packhouse_resource_id
      set_column_allow_null :production_line_id
      set_column_allow_null :scanned_from_carton_id
    end
  end

  down do
    alter_table(:pallets) do
      drop_constraint :depot_plt_ph_line_check
      set_column_not_null :plt_packhouse_resource_id
      set_column_not_null :plt_line_resource_id
    end

    alter_table(:pallet_sequences) do
      set_column_not_null :production_run_id
      set_column_not_null :packhouse_resource_id
      set_column_not_null :production_line_id
      set_column_not_null :scanned_from_carton_id
    end
  end
end
