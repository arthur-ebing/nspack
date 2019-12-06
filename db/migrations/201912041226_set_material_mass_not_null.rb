Sequel.migration do
  up do
    run "UPDATE standard_pack_codes SET material_mass = 0 WHERE material_mass IS NULL;
         UPDATE pallet_bases SET material_mass = 0 WHERE material_mass IS NULL;"
    alter_table(:standard_pack_codes) do
      set_column_not_null :material_mass
    end
    alter_table(:pallet_bases) do
      set_column_not_null :material_mass
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      set_column_allow_null :material_mass
    end
    alter_table(:pallet_bases) do
      set_column_allow_null :material_mass
    end
  end
end
