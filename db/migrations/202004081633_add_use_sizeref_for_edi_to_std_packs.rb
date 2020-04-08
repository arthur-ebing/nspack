Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      add_column :use_size_ref_for_edi, TrueClass, default: false
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      drop_column :use_size_ref_for_edi
    end
  end
end
