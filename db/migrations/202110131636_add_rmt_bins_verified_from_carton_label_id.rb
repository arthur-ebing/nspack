Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      add_foreign_key :verified_from_carton_label_id, :carton_labels, key: [:id]
    end

    alter_table(:product_setups) do
      add_column :rebin, :boolean, default: false
    end
  end

  down do
    alter_table(:rmt_bins) do
      drop_column :verified_from_carton_label_id
    end

    alter_table(:product_setups) do
      drop_column :rebin
    end
  end
end