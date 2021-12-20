require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    # QC SAMPLE TYPES
    create_table(:qc_sample_types, ignore_index_errors: true) do
      primary_key :id
      String :qc_sample_type_name, null: false, unique: true
      String :description, text: true
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_sample_types,
                   :created_at,
                   function_name: :pgt_qc_sample_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_sample_types,
                   :updated_at,
                   function_name: :pgt_qc_sample_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_sample_types', true, true, '{updated_at}'::text[]);"

    # QC MEASUREMENT TYPES
    create_table(:qc_measurement_types, ignore_index_errors: true) do
      primary_key :id
      String :qc_measurement_type_name, null: false, unique: true
      String :description, text: true
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_measurement_types,
                   :created_at,
                   function_name: :pgt_qc_measurement_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_measurement_types,
                   :updated_at,
                   function_name: :pgt_qc_measurement_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_measurement_types', true, true, '{updated_at}'::text[]);"

    # QC TEST TYPES
    create_table(:qc_test_types, ignore_index_errors: true) do
      primary_key :id
      String :qc_test_type_name, null: false, unique: true
      String :description, text: true
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_test_types,
                   :created_at,
                   function_name: :pgt_qc_test_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_test_types,
                   :updated_at,
                   function_name: :pgt_qc_test_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_test_types', true, true, '{updated_at}'::text[]);"

    # FRUIT DEFECT TYPES
    create_table(:fruit_defect_types, ignore_index_errors: true) do
      primary_key :id
      String :fruit_defect_type_name, null: false, unique: true
      String :description, text: true
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:fruit_defect_types,
                   :created_at,
                   function_name: :pgt_fruit_defect_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:fruit_defect_types,
                   :updated_at,
                   function_name: :pgt_fruit_defect_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('fruit_defect_types', true, true, '{updated_at}'::text[]);"

    # FRUIT DEFECTS
    create_table(:fruit_defects, ignore_index_errors: true) do
      primary_key :id
      foreign_key :rmt_class_id, :rmt_classes, null: false
      foreign_key :fruit_defect_type_id, :fruit_defect_types, null: false
      String :fruit_defect_code, null: false, unique: true
      String :short_description, null: false
      String :description
      TrueClass :internal, default: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:fruit_defects,
                   :created_at,
                   function_name: :pgt_fruit_defects_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:fruit_defects,
                   :updated_at,
                   function_name: :pgt_fruit_defects_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('fruit_defects', true, true, '{updated_at}'::text[]);"

    # QC SAMPLES
    create_table(:qc_samples, ignore_index_errors: true) do
      primary_key :id
      foreign_key :qc_sample_type_id, :qc_sample_types, null: false
      foreign_key :rmt_delivery_id, :rmt_deliveries
      foreign_key :coldroom_location_id, :locations
      foreign_key :production_run_id, :production_runs
      foreign_key :orchard_id, :orchards
      String :presort_run_lot_number
      String :ref_number, null: false, unique: true
      String :short_description
      Integer :sample_size, null: false
      TrueClass :editing, default: true
      TrueClass :completed, default: false
      DateTime :completed_at
      column :rmt_bin_ids, 'int[]'
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_samples,
                   :created_at,
                   function_name: :pgt_qc_samples_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_samples,
                   :updated_at,
                   function_name: :pgt_qc_samples_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_samples', true, true, '{updated_at}'::text[]);"

    # QC TESTS
    create_table(:qc_tests, ignore_index_errors: true) do
      primary_key :id
      foreign_key :qc_measurement_type_id, :qc_measurement_types, null: false
      foreign_key :qc_sample_id, :qc_samples, null: false
      foreign_key :qc_test_type_id, :qc_test_types, null: false
      foreign_key :instrument_plant_resource_id, :plant_resources
      Integer :sample_size, null: false
      TrueClass :editing, default: true
      TrueClass :completed, default: false
      DateTime :completed_at
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_tests,
                   :created_at,
                   function_name: :pgt_qc_tests_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_tests,
                   :updated_at,
                   function_name: :pgt_qc_tests_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_tests', true, true, '{updated_at}'::text[]);"

    # QC STARCH MEASUREMENTS
    create_table(:qc_starch_measurements, ignore_index_errors: true) do
      primary_key :id
      foreign_key :qc_test_id, :qc_tests, null: false
      Integer :starch_precentage, null: false
      Integer :qty_fruit_with_percentage, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_starch_measurements,
                   :created_at,
                   function_name: :pgt_qc_starch_measurements_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_starch_measurements,
                   :updated_at,
                   function_name: :pgt_qc_starch_measurements_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_starch_measurements', true, true, '{updated_at}'::text[]);"

    # QC DEFECT MEASUREMENT
    create_table(:qc_defect_measurements, ignore_index_errors: true) do
      primary_key :id
      foreign_key :qc_test_id, :qc_tests, null: false
      foreign_key :rmt_class_id, :rmt_classes, null: false
      foreign_key :fruit_defect_id, :fruit_defects, null: false
      Integer :qty_fruit_with_percentage, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_defect_measurements,
                   :created_at,
                   function_name: :pgt_qc_defect_measurements_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_defect_measurements,
                   :updated_at,
                   function_name: :pgt_qc_defect_measurements_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_defect_measurements', true, true, '{updated_at}'::text[]);"

    # QC INSTRUMENT MEASUREMENTS
    create_table(:qc_instrument_measurements, ignore_index_errors: true) do
      primary_key :id
      foreign_key :qc_test_id, :qc_tests, null: false
      column :measurements, 'decimal[]'
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:qc_instrument_measurements,
                   :created_at,
                   function_name: :pgt_qc_instrument_measurements_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qc_instrument_measurements,
                   :updated_at,
                   function_name: :pgt_qc_instrument_measurements_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qc_instrument_measurements', true, true, '{updated_at}'::text[]);"

    # ALTER PLANT/SYS RESOURCES (meas types arr, instrument type, model, serial, properties)
    # (All in sys properties ext config?)
    # resource type: peripheral / qc instrument
    # equip type: FTA
    # model: gauss....
  end

  down do
    # QC INSTRUMENT MEASUREMENTS
    drop_trigger(:qc_instrument_measurements, :audit_trigger_row)
    drop_trigger(:qc_instrument_measurements, :audit_trigger_stm)

    drop_trigger(:qc_instrument_measurements, :set_created_at)
    drop_function(:pgt_qc_instrument_measurements_set_created_at)
    drop_trigger(:qc_instrument_measurements, :set_updated_at)
    drop_function(:pgt_qc_instrument_measurements_set_updated_at)
    drop_table(:qc_instrument_measurements)

    # QC DEFECT MEASUREMENT
    drop_trigger(:qc_defect_measurements, :audit_trigger_row)
    drop_trigger(:qc_defect_measurements, :audit_trigger_stm)

    drop_trigger(:qc_defect_measurements, :set_created_at)
    drop_function(:pgt_qc_defect_measurements_set_created_at)
    drop_trigger(:qc_defect_measurements, :set_updated_at)
    drop_function(:pgt_qc_defect_measurements_set_updated_at)
    drop_table(:qc_defect_measurements)

    # QC STARCH MEASUREMENTS
    drop_trigger(:qc_starch_measurements, :audit_trigger_row)
    drop_trigger(:qc_starch_measurements, :audit_trigger_stm)

    drop_trigger(:qc_starch_measurements, :set_created_at)
    drop_function(:pgt_qc_starch_measurements_set_created_at)
    drop_trigger(:qc_starch_measurements, :set_updated_at)
    drop_function(:pgt_qc_starch_measurements_set_updated_at)
    drop_table(:qc_starch_measurements)

    # QC TESTS
    drop_trigger(:qc_tests, :audit_trigger_row)
    drop_trigger(:qc_tests, :audit_trigger_stm)

    drop_trigger(:qc_tests, :set_created_at)
    drop_function(:pgt_qc_tests_set_created_at)
    drop_trigger(:qc_tests, :set_updated_at)
    drop_function(:pgt_qc_tests_set_updated_at)
    drop_table(:qc_tests)

    # QC SAMPLES
    drop_trigger(:qc_samples, :audit_trigger_row)
    drop_trigger(:qc_samples, :audit_trigger_stm)

    drop_trigger(:qc_samples, :set_created_at)
    drop_function(:pgt_qc_samples_set_created_at)
    drop_trigger(:qc_samples, :set_updated_at)
    drop_function(:pgt_qc_samples_set_updated_at)
    drop_table(:qc_samples)

    # FRUIT DEFECTS
    drop_trigger(:fruit_defects, :audit_trigger_row)
    drop_trigger(:fruit_defects, :audit_trigger_stm)

    drop_trigger(:fruit_defects, :set_created_at)
    drop_function(:pgt_fruit_defects_set_created_at)
    drop_trigger(:fruit_defects, :set_updated_at)
    drop_function(:pgt_fruit_defects_set_updated_at)
    drop_table(:fruit_defects)

    # FRUIT DEFECT TYPES
    drop_trigger(:fruit_defect_types, :audit_trigger_row)
    drop_trigger(:fruit_defect_types, :audit_trigger_stm)

    drop_trigger(:fruit_defect_types, :set_created_at)
    drop_function(:pgt_fruit_defect_types_set_created_at)
    drop_trigger(:fruit_defect_types, :set_updated_at)
    drop_function(:pgt_fruit_defect_types_set_updated_at)
    drop_table(:fruit_defect_types)

    # QC TEST TYPES
    drop_trigger(:qc_test_types, :audit_trigger_row)
    drop_trigger(:qc_test_types, :audit_trigger_stm)

    drop_trigger(:qc_test_types, :set_created_at)
    drop_function(:pgt_qc_test_types_set_created_at)
    drop_trigger(:qc_test_types, :set_updated_at)
    drop_function(:pgt_qc_test_types_set_updated_at)
    drop_table(:qc_test_types)

    # QC MEASUREMENT TYPES
    drop_trigger(:qc_measurement_types, :audit_trigger_row)
    drop_trigger(:qc_measurement_types, :audit_trigger_stm)

    drop_trigger(:qc_measurement_types, :set_created_at)
    drop_function(:pgt_qc_measurement_types_set_created_at)
    drop_trigger(:qc_measurement_types, :set_updated_at)
    drop_function(:pgt_qc_measurement_types_set_updated_at)
    drop_table(:qc_measurement_types)

    # QC SAMPLE TYPES
    drop_trigger(:qc_sample_types, :audit_trigger_row)
    drop_trigger(:qc_sample_types, :audit_trigger_stm)

    drop_trigger(:qc_sample_types, :set_created_at)
    drop_function(:pgt_qc_sample_types_set_created_at)
    drop_trigger(:qc_sample_types, :set_updated_at)
    drop_function(:pgt_qc_sample_types_set_updated_at)
    drop_table(:qc_sample_types)
  end
end
