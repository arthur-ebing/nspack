require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:rmt_bin_labels, ignore_index_errors: true) do
      primary_key :id
      foreign_key :cultivar_id, :cultivars, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :puc_id, :pucs, type: :integer, null: false
      foreign_key :orchard_id, :orchards, type: :integer, null: false
      DateTime :created_at, null: false
      DateTime :bin_received_at
      String :bin_asset_number, null: false
    end

    pgt_created_at(:rmt_bin_labels,
                   :created_at,
                   function_name: :rmt_bin_labels_set_created_at,
                   trigger_name: :set_created_at)
  end

  down do
    drop_trigger(:rmt_bin_labels, :set_created_at)
    drop_function(:rmt_bin_labels_set_created_at)
    drop_table(:rmt_bin_labels)
  end
end
