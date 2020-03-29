require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:pallet_mix_rules, ignore_index_errors: true) do
      primary_key :id
      String :scope
      Integer :production_run_id
      Integer :pallet_id
      TrueClass :allow_tm_mix
      TrueClass :allow_grade_mix
      TrueClass :allow_size_ref_mix
      TrueClass :allow_pack_mix
      TrueClass :allow_std_count_mix
      TrueClass :allow_mark_mix
      TrueClass :allow_inventory_code_mix
    end
  end

  down do
    drop_table(:pallet_mix_rules)
  end
end
