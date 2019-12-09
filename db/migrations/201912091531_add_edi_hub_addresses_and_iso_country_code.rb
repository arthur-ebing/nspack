Sequel.migration do
  up do
    alter_table(:depots) do
      rename_column :edi_code, :edi_hub_address
      # add_constraint(:edi_hub_address_len) { char_length(coalesce(edi_hub_address, 'xxx')) == 3 }
    end

    alter_table(:organizations) do
      add_column :edi_hub_address, String
    end

    alter_table(:destination_countries) do
      add_column :iso_country_code, String
    end
  end

  down do
    alter_table(:depots) do
      # drop_constraint(:edi_hub_address_len)
      rename_column :edi_hub_address, :edi_code
    end

    alter_table(:organizations) do
      drop_column :edi_hub_address
    end

    alter_table(:destination_countries) do
      drop_column :iso_country_code
    end
  end
end
