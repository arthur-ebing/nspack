Sequel.migration do
  up do
    alter_table(:standard_pack_codes) do
      add_column :palletizer_incentive_rate, :decimal, default: 0
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      drop_column :palletizer_incentive_rate
    end
  end
end
