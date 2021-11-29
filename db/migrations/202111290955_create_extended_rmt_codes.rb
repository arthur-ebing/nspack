require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    # RIPENESS CODES
    # -----------------------------------
    create_table(:ripeness_codes, ignore_index_errors: true) do
      primary_key :id
      String :ripeness_code, null: false, unique: true
      String :description
      String :legacy_code
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:ripeness_codes,
                   :created_at,
                   function_name: :pgt_ripeness_codes_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:ripeness_codes,
                   :updated_at,
                   function_name: :pgt_ripeness_codes_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('ripeness_codes', true, true, '{updated_at}'::text[]);"

    # RMT CLASSIFICATION TYPES
    # -----------------------------------
    create_table(:rmt_classification_types, ignore_index_errors: true) do
      primary_key :id
      String :rmt_classification_type_code, null: false, unique: true
      String :description
      TrueClass :required_for_delivery, default: false
      TrueClass :physical_attribute, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:rmt_classification_types,
                   :created_at,
                   function_name: :pgt_rmt_classification_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_classification_types,
                   :updated_at,
                   function_name: :pgt_rmt_classification_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_classification_types', true, true, '{updated_at}'::text[]);"

    # RMT VARIANTS
    # -----------------------------------
    create_table(:rmt_variants, ignore_index_errors: true) do
      primary_key :id
      foreign_key :cultivar_id, :cultivars, null: false
      String :rmt_variant_code, null: false, unique: true
      String :description
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:rmt_variants,
                   :created_at,
                   function_name: :pgt_rmt_variants_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_variants,
                   :updated_at,
                   function_name: :pgt_rmt_variants_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_variants', true, true, '{updated_at}'::text[]);"

    # RMT HANDLING REGIMES
    # -----------------------------------
    create_table(:rmt_handling_regimes, ignore_index_errors: true) do
      primary_key :id
      String :regime_code, null: false, unique: true
      String :description
      TrueClass :for_packing, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:rmt_handling_regimes,
                   :created_at,
                   function_name: :pgt_rmt_handling_regimes_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_handling_regimes,
                   :updated_at,
                   function_name: :pgt_rmt_handling_regimes_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_handling_regimes', true, true, '{updated_at}'::text[]);"

    # RMT CLASSIFICATIONS
    # -----------------------------------
    create_table(:rmt_classifications, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_classification_type_id, :rmt_classification_types, type: :integer, null: false
      String :rmt_classification, null: false, unique: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:rmt_classifications,
                   :created_at,
                   function_name: :pgt_rmt_classifications_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_classifications,
                   :updated_at,
                   function_name: :pgt_rmt_classifications_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_classifications', true, true, '{updated_at}'::text[]);"

    # RMT CODES
    # -----------------------------------
    create_table(:rmt_codes, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_variant_id, :rmt_variants, null: false
      foreign_key :rmt_handling_regime_id, :rmt_handling_regimes, null: false
      String :rmt_code, null: false, unique: true
      String :description
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:rmt_codes,
                   :created_at,
                   function_name: :pgt_rmt_codes_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:rmt_codes,
                   :updated_at,
                   function_name: :pgt_rmt_codes_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('rmt_codes', true, true, '{updated_at}'::text[]);"

    # RMT DELIVERIES
    # -----------------------------------
    alter_table(:rmt_deliveries) do
      add_foreign_key :rmt_code_id , :rmt_codes
      add_column :rmt_classifications, 'int[]'
      add_column :rmt_treatments, 'int[]'
    end

    # RMT BINS
    # -----------------------------------
    alter_table(:rmt_bins) do
      add_foreign_key :rmt_code_id , :rmt_codes
      add_foreign_key :main_ripeness_treatment_id , :treatments
      add_foreign_key :main_cold_treatment_id , :treatments
      add_column :rmt_classifications, 'int[]'
      add_column :rmt_treatments, 'int[]'
    end
  end

  down do
    # RMT BINS
    alter_table(:rmt_bins) do
      drop_column :rmt_code_id
      drop_column :main_ripeness_treatment_id
      drop_column :rmt_classifications
      drop_column :rmt_treatments
    end

    # RMT DELIVERIES
    alter_table(:rmt_deliveries) do
      drop_column :rmt_code_id
      drop_column :rmt_classifications
      drop_column :rmt_treatments
    end

    # RMT CODES
    drop_trigger(:rmt_codes, :audit_trigger_row)
    drop_trigger(:rmt_codes, :audit_trigger_stm)

    drop_trigger(:rmt_codes, :set_created_at)
    drop_function(:pgt_rmt_codes_set_created_at)
    drop_trigger(:rmt_codes, :set_updated_at)
    drop_function(:pgt_rmt_codes_set_updated_at)
    drop_table(:rmt_codes)

    # RMT CLASSIFICATIONS
    drop_trigger(:rmt_classifications, :audit_trigger_row)
    drop_trigger(:rmt_classifications, :audit_trigger_stm)

    drop_trigger(:rmt_classifications, :set_created_at)
    drop_function(:pgt_rmt_classifications_set_created_at)
    drop_trigger(:rmt_classifications, :set_updated_at)
    drop_function(:pgt_rmt_classifications_set_updated_at)
    drop_table(:rmt_classifications)

    # RMT HANDLING REGIMES
    drop_trigger(:rmt_handling_regimes, :audit_trigger_row)
    drop_trigger(:rmt_handling_regimes, :audit_trigger_stm)

    drop_trigger(:rmt_handling_regimes, :set_created_at)
    drop_function(:pgt_rmt_handling_regimes_set_created_at)
    drop_trigger(:rmt_handling_regimes, :set_updated_at)
    drop_function(:pgt_rmt_handling_regimes_set_updated_at)
    drop_table(:rmt_handling_regimes)

    # RMT VARIANTS
    drop_trigger(:rmt_variants, :audit_trigger_row)
    drop_trigger(:rmt_variants, :audit_trigger_stm)

    drop_trigger(:rmt_variants, :set_created_at)
    drop_function(:pgt_rmt_variants_set_created_at)
    drop_trigger(:rmt_variants, :set_updated_at)
    drop_function(:pgt_rmt_variants_set_updated_at)
    drop_table(:rmt_variants)

    # RMT CLASSIFICATION TYPES
    drop_trigger(:rmt_classification_types, :audit_trigger_row)
    drop_trigger(:rmt_classification_types, :audit_trigger_stm)

    drop_trigger(:rmt_classification_types, :set_created_at)
    drop_function(:pgt_rmt_classification_types_set_created_at)
    drop_trigger(:rmt_classification_types, :set_updated_at)
    drop_function(:pgt_rmt_classification_types_set_updated_at)
    drop_table(:rmt_classification_types)

    # RIPENESS CODES
    drop_trigger(:ripeness_codes, :audit_trigger_row)
    drop_trigger(:ripeness_codes, :audit_trigger_stm)

    drop_trigger(:ripeness_codes, :set_created_at)
    drop_function(:pgt_ripeness_codes_set_created_at)
    drop_trigger(:ripeness_codes, :set_updated_at)
    drop_function(:pgt_ripeness_codes_set_updated_at)
    drop_table(:ripeness_codes)
  end
end
