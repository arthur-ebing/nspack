Sequel.migration do
  up do
    alter_table(:basic_pack_codes) do
      add_unique_constraint :basic_pack_code, name: :basic_pack_codes_uniq_code
    end
    alter_table(:standard_pack_codes) do
      add_unique_constraint :standard_pack_code, name: :standard_pack_codes_uniq_code
    end
  end

  down do
    alter_table(:basic_pack_codes) do
      drop_constraint :basic_pack_codes_uniq_code
    end
    alter_table(:standard_pack_codes) do
      drop_constraint :standard_pack_codes_uniq_code
    end
  end
end
