Sequel.migration do
  up do
    alter_table(:pallet_sequences) do
      add_column :depot_pallet, :boolean, default: false

      add_constraint(:depot_pltseq_ph_line_check) { Sequel.lit('depot_pallet OR (packhouse_resource_id IS NOT NULL AND production_line_id IS NOT NULL)') }
    end

    alter_table(:standard_pack_codes) do
      add_foreign_key :basic_pack_code_id, :basic_pack_codes
    end

    if ENV['CLIENT_CODE'] == 'um'
      run <<~SQL
        UPDATE standard_pack_codes
        SET basic_pack_code_id = (SELECT id from basic_pack_codes WHERE basic_pack_code = standard_pack_codes.standard_pack_code)
      SQL
    else
      run <<~SQL
        UPDATE standard_pack_codes
        SET basic_pack_code_id = (SELECT basic_pack_code_id
                                  FROM fruit_actual_counts_for_packs f
                                  WHERE standard_pack_codes.id = ANY(f.standard_pack_code_ids)
                                  LIMIT 1)
      SQL
    end
  end

  down do
    alter_table(:pallet_sequences) do
      drop_constraint :depot_pltseq_ph_line_check

      drop_column :depot_pallet
    end

    alter_table(:standard_pack_codes) do
      drop_foreign_key :basic_pack_code_id
    end
  end
end
