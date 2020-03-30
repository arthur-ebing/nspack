require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:pallet_mix_rules, ignore_index_errors: true) do
      primary_key :id
      String :scope
      foreign_key :production_run_id, :production_runs, type: :integer
      foreign_key :pallet_id, :pallets, type: :integer
      TrueClass :allow_tm_mix, default: false
      TrueClass :allow_grade_mix, default: false
      TrueClass :allow_size_ref_mix, default: false
      TrueClass :allow_pack_mix, default: false
      TrueClass :allow_std_count_mix, default: false
      TrueClass :allow_mark_mix, default: false
      TrueClass :allow_inventory_code_mix, default: false
    end
  end

  down do
    drop_table(:pallet_mix_rules)
  end
end
