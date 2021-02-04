Sequel.migration do
  up do
    create_table(:basic_packs_standard_packs, ignore_index_errors: true) do
      foreign_key :basic_pack_id, :basic_pack_codes, null: false
      foreign_key :standard_pack_id, :standard_pack_codes, null: false
      index [:basic_pack_id, :standard_pack_id], name: :basic_packs_standard_packs_unique_code, unique: true
    end

    run "INSERT INTO basic_packs_standard_packs (standard_pack_id, basic_pack_id) SELECT id, basic_pack_code_id FROM standard_pack_codes ON CONFLICT DO NOTHING;"

    alter_table(:standard_pack_codes) do
      drop_foreign_key :basic_pack_code_id
    end
  end

  down do
    alter_table(:standard_pack_codes) do
      add_foreign_key :basic_pack_code_id, :basic_pack_codes
    end

    run "UPDATE standard_pack_codes SET basic_pack_code_id = (SELECT basic_pack_id FROM basic_packs_standard_packs WHERE standard_pack_codes.id = basic_packs_standard_packs.standard_pack_id LIMIT 1);"

    drop_table(:basic_packs_standard_packs)
  end
end