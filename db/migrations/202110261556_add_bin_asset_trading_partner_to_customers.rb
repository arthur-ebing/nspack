require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    alter_table(:customers) do
      add_column :bin_asset_trading_partner, TrueClass, default: false
      add_foreign_key :location_id , :locations, key: [:id]
    end
  end

  down do
    alter_table(:customers) do
      drop_column :bin_asset_trading_partner
      drop_column :location_id
    end
  end
end
