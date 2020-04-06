Sequel.migration do
  up do
    alter_table(:commodities) do
      add_column :use_size_ref_for_edi, TrueClass, default: false
    end
  end

  down do
    alter_table(:commodities) do
      drop_column :use_size_ref_for_edi
    end
  end
end
