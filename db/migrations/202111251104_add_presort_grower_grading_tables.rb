require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    # PRESORT GROWER GRADING POOLS
    create_table(:presort_grower_grading_pools, ignore_index_errors: true) do
      primary_key :id
      String :maf_lot_number, null: false
      String :description
      String :track_slms_indicator_code
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :commodity_id, :commodities, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      Integer :rmt_bin_count
      Decimal :rmt_bin_weight
      Decimal :pro_rata_factor
      TrueClass :completed, default: false
      TrueClass :active, default: true
      String :created_by
      String :updated_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:maf_lot_number, :farm_id], name: :presort_grower_grading_pools_unique_code, unique: true
    end

    pgt_created_at(:presort_grower_grading_pools,
                   :created_at,
                   function_name: :presort_grower_grading_pools_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:presort_grower_grading_pools,
                   :updated_at,
                   function_name: :presort_grower_grading_pools_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('presort_grower_grading_pools', true, true, '{updated_at}'::text[]);"

    # PRESORT GROWER GRADING BINS
    create_table(:presort_grower_grading_bins, ignore_index_errors: true) do
      primary_key :id
      foreign_key :presort_grower_grading_pool_id, :presort_grower_grading_pools, type: :integer, null: false
      foreign_key :farm_id, :farms, type: :integer, null: false
      foreign_key :rmt_class_id, :rmt_classes, type: :integer
      foreign_key :rmt_size_id, :rmt_sizes, type: :integer
      String :maf_rmt_code
      String :maf_article
      String :maf_class
      String :maf_colour
      String :maf_count
      String :maf_article_count
      Decimal :maf_weight
      Integer :maf_tipped_quantity
      Decimal :maf_total_lot_weight
      TrueClass :active, default: true
      String :created_by
      String :updated_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:presort_grower_grading_bins,
                   :created_at,
                   function_name: :presort_grower_grading_bins_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:presort_grower_grading_bins,
                   :updated_at,
                   function_name: :presort_grower_grading_bins_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('presort_grower_grading_bins', true, true, '{updated_at}'::text[]);"
  end

  down do
    drop_trigger(:presort_grower_grading_bins, :audit_trigger_row)
    drop_trigger(:presort_grower_grading_bins, :audit_trigger_stm)

    drop_trigger(:presort_grower_grading_bins, :set_created_at)
    drop_function(:presort_grower_grading_bins_set_created_at)
    drop_trigger(:presort_grower_grading_bins, :set_updated_at)
    drop_function(:presort_grower_grading_bins_set_updated_at)
    drop_table(:presort_grower_grading_bins)

    drop_trigger(:presort_grower_grading_pools, :audit_trigger_row)
    drop_trigger(:presort_grower_grading_pools, :audit_trigger_stm)

    drop_trigger(:presort_grower_grading_pools, :set_created_at)
    drop_function(:presort_grower_grading_pools_set_created_at)
    drop_trigger(:presort_grower_grading_pools, :set_updated_at)
    drop_function(:presort_grower_grading_pools_set_updated_at)
    drop_table(:presort_grower_grading_pools)
  end
end
