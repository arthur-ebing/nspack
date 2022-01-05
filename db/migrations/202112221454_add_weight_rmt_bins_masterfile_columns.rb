Sequel.migration do
  up do
    alter_table(:cultivars) do
      add_column :std_rmt_bin_nett_weight, :decimal
    end

    alter_table(:commodities) do
      add_column :derive_rmt_nett_weight, :boolean, default: false
    end
  end

  down do
    alter_table(:cultivars) do
      drop_column :std_rmt_bin_nett_weight
    end

    alter_table(:commodities) do
      drop_column :derive_rmt_nett_weight
    end
  end
end
