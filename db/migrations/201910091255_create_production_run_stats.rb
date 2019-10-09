require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:production_run_stats, ignore_index_errors: true) do
      primary_key :id
      foreign_key :production_run_id, :production_runs, type: :integer, null: false
      Integer :bins_tipped, default: 0
      Decimal :bins_tipped_weight, default: 0
      Integer :carton_labels_printed, default: 0
      Integer :cartons_verified, default: 0
      Decimal :cartons_verified_weight, default: 0
      Integer :pallets_palletized, default: 0
      Integer :pallets_inspected, default: 0
      Integer :rebins_created, default: 0
      Decimal :rebins_weight, default: 0
    end
  end

  down do
    drop_table(:production_run_stats)
  end
end
