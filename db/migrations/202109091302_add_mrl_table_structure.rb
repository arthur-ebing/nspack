require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    # CHEMICALS
    create_table(:chemicals, ignore_index_errors: true) do
      primary_key :id
      String :chemical_name, null: false
      String :description
      Decimal :eu_max_level, null: false
      Decimal :arfd_max_level
      TrueClass :orchard_chemical, default: true
      TrueClass :drench_chemical, default: false
      TrueClass :packline_chemical, default: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:chemical_name], name: :chemicals_unique_code, unique: true
    end

    pgt_created_at(:chemicals,
                   :created_at,
                   function_name: :chemicals_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:chemicals,
                   :updated_at,
                   function_name: :chemicals_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('chemicals', true, true, '{updated_at}'::text[]);"

    # QA STANDARD TYPES
    create_table(:qa_standard_types, ignore_index_errors: true) do
      primary_key :id
      String :qa_standard_type_code, null: false
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:qa_standard_type_code], name: :qa_standard_types_unique_code, unique: true
    end

    pgt_created_at(:qa_standard_types,
                   :created_at,
                   function_name: :qa_standard_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qa_standard_types,
                   :updated_at,
                   function_name: :qa_standard_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qa_standard_types', true, true, '{updated_at}'::text[]);"

    # QA STANDARDS
    create_table(:qa_standards, ignore_index_errors: true) do
      primary_key :id
      String :qa_standard_name, null: false
      String :description
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :qa_standard_type_id, :qa_standard_types, type: :integer, null: false
      column :target_market_ids, 'int[]'
      column :packed_tm_group_ids, 'int[]'
      TrueClass :internal_standard, default: false
      TrueClass :applies_to_all_markets, default: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:qa_standard_name], name: :qa_standards_unique_code, unique: true
    end

    pgt_created_at(:qa_standards,
                   :created_at,
                   function_name: :qa_standards_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:qa_standards,
                   :updated_at,
                   function_name: :qa_standards_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('qa_standards', true, true, '{updated_at}'::text[]);"

    # MRL REQUIREMENTS
    create_table(:mrl_requirements, ignore_index_errors: true) do
      primary_key :id
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :qa_standard_id, :qa_standards, type: :integer, null: false
      foreign_key :packed_tm_group_id, :target_market_groups, type: :integer
      foreign_key :target_market_id, :target_markets, type: :integer
      foreign_key :target_customer_id, :party_roles, type: :integer
      foreign_key :cultivar_group_id, :cultivar_groups, type: :integer
      foreign_key :cultivar_id, :cultivars, type: :integer
      Integer :max_num_chemicals_allowed, null: false
      TrueClass :require_orchard_level_results, default: false
      TrueClass :no_results_equal_failure, default: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:mrl_requirements,
                   :created_at,
                   function_name: :mrl_requirements_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:mrl_requirements,
                   :updated_at,
                   function_name: :mrl_requirements_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('mrl_requirements', true, true, '{updated_at}'::text[]);"

    # MRL CHEMICALS REQUIREMENTS
    create_table(:mrl_chemicals_requirements, ignore_index_errors: true) do
      primary_key :id
      foreign_key :chemical_id, :chemicals, type: :integer, null: false
      foreign_key :mrl_requirement_id, :mrl_requirements, type: :integer, null: false
      Decimal :percentage_of_eu_level
      Decimal :maximum_residue_level
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:mrl_chemicals_requirements,
                   :created_at,
                   function_name: :mrl_chemicals_requirements_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:mrl_chemicals_requirements,
                   :updated_at,
                   function_name: :mrl_chemicals_requirements_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('mrl_chemicals_requirements', true, true, '{updated_at}'::text[]);"

    # MRL SAMPLE TYPES
    create_table(:mrl_sample_types, ignore_index_errors: true) do
      primary_key :id
      String :sample_type_code, null: false
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:sample_type_code], name: :mrl_sample_types_unique_code, unique: true
    end

    pgt_created_at(:mrl_sample_types,
                   :created_at,
                   function_name: :mrl_sample_types_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:mrl_sample_types,
                   :updated_at,
                   function_name: :mrl_sample_types_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('mrl_sample_types', true, true, '{updated_at}'::text[]);"

    # LABORATORIES
    create_table(:laboratories, ignore_index_errors: true) do
      primary_key :id
      String :lab_code, null: false
      String :lab_name
      String :description
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:lab_code], name: :laboratories_unique_code, unique: true
    end

    pgt_created_at(:laboratories,
                   :created_at,
                   function_name: :laboratories_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:laboratories,
                   :updated_at,
                   function_name: :laboratories_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('laboratories', true, true, '{updated_at}'::text[]);"

    # MRL RESULTS
    create_table(:mrl_results, ignore_index_errors: true) do
      primary_key :id
      foreign_key :post_harvest_parent_mrl_result_id, :mrl_results, type: :integer
      foreign_key :cultivar_id, :cultivars, type: :integer
      foreign_key :puc_id, :pucs, type: :integer
      foreign_key :season_id, :seasons, type: :integer, null: false
      foreign_key :rmt_delivery_id, :rmt_deliveries, type: :integer
      foreign_key :farm_id, :farms, type: :integer
      foreign_key :laboratory_id, :laboratories, type: :integer, null: false
      foreign_key :mrl_sample_type_id, :mrl_sample_types, type: :integer, null: false
      foreign_key :orchard_id, :orchards, type: :integer
      foreign_key :production_run_id, :production_runs, type: :integer
      String :waybill_number
      String :reference_number
      String :sample_number, null: false
      Integer :ph_level
      Integer :num_active_ingredients
      TrueClass :max_num_chemicals_passed, default: false
      TrueClass :mrl_sample_passed, default: false
      TrueClass :pre_harvest_result, default: false
      TrueClass :post_harvest_result, default: false
      TrueClass :active, default: true
      DateTime :fruit_received_at, null: false
      DateTime :sample_submitted_at, null: false
      DateTime :result_received_at, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:mrl_results,
                   :created_at,
                   function_name: :mrl_results_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:mrl_results,
                   :updated_at,
                   function_name: :mrl_results_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('mrl_results', true, true, '{updated_at}'::text[]);"

    # MRL CHEMICALS RESULTS
    create_table(:mrl_chemicals_results, ignore_index_errors: true) do
      primary_key :id
      foreign_key :mrl_result_id, :mrl_results, type: :integer, null: false
      foreign_key :chemical_id, :chemicals, type: :integer, null: false
      Decimal :percentage_of_eu_level
      Decimal :mrl_level_detected
      TrueClass :passed, default: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    pgt_created_at(:mrl_chemicals_results,
                   :created_at,
                   function_name: :mrl_chemicals_results_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:mrl_chemicals_results,
                   :updated_at,
                   function_name: :mrl_chemicals_results_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('mrl_chemicals_results', true, true, '{updated_at}'::text[]);"

  end

  down do

    drop_trigger(:mrl_chemicals_results, :audit_trigger_row)
    drop_trigger(:mrl_chemicals_results, :audit_trigger_stm)

    drop_trigger(:mrl_chemicals_results, :set_created_at)
    drop_function(:mrl_chemicals_results_set_created_at)
    drop_trigger(:mrl_chemicals_results, :set_updated_at)
    drop_function(:mrl_chemicals_results_set_updated_at)
    drop_table(:mrl_chemicals_results)

    drop_trigger(:mrl_results, :audit_trigger_row)
    drop_trigger(:mrl_results, :audit_trigger_stm)

    drop_trigger(:mrl_results, :set_created_at)
    drop_function(:mrl_results_set_created_at)
    drop_trigger(:mrl_results, :set_updated_at)
    drop_function(:mrl_results_set_updated_at)
    drop_table(:mrl_results)

    drop_trigger(:mrl_sample_types, :audit_trigger_row)
    drop_trigger(:mrl_sample_types, :audit_trigger_stm)

    drop_trigger(:mrl_sample_types, :set_created_at)
    drop_function(:mrl_sample_types_set_created_at)
    drop_trigger(:mrl_sample_types, :set_updated_at)
    drop_function(:mrl_sample_types_set_updated_at)
    drop_table(:mrl_sample_types)

    drop_trigger(:laboratories, :audit_trigger_row)
    drop_trigger(:laboratories, :audit_trigger_stm)

    drop_trigger(:laboratories, :set_created_at)
    drop_function(:laboratories_set_created_at)
    drop_trigger(:laboratories, :set_updated_at)
    drop_function(:laboratories_set_updated_at)
    drop_table(:laboratories)

    drop_trigger(:mrl_chemicals_requirements, :audit_trigger_row)
    drop_trigger(:mrl_chemicals_requirements, :audit_trigger_stm)

    drop_trigger(:mrl_chemicals_requirements, :set_created_at)
    drop_function(:mrl_chemicals_requirements_set_created_at)
    drop_trigger(:mrl_chemicals_requirements, :set_updated_at)
    drop_function(:mrl_chemicals_requirements_set_updated_at)
    drop_table(:mrl_chemicals_requirements)

    drop_trigger(:mrl_requirements, :audit_trigger_row)
    drop_trigger(:mrl_requirements, :audit_trigger_stm)

    drop_trigger(:mrl_requirements, :set_created_at)
    drop_function(:mrl_requirements_set_created_at)
    drop_trigger(:mrl_requirements, :set_updated_at)
    drop_function(:mrl_requirements_set_updated_at)
    drop_table(:mrl_requirements)

    drop_trigger(:qa_standards, :audit_trigger_row)
    drop_trigger(:qa_standards, :audit_trigger_stm)

    drop_trigger(:qa_standards, :set_created_at)
    drop_function(:qa_standards_set_created_at)
    drop_trigger(:qa_standards, :set_updated_at)
    drop_function(:qa_standards_set_updated_at)
    drop_table(:qa_standards)

    drop_trigger(:qa_standard_types, :audit_trigger_row)
    drop_trigger(:qa_standard_types, :audit_trigger_stm)

    drop_trigger(:qa_standard_types, :set_created_at)
    drop_function(:qa_standard_types_set_created_at)
    drop_trigger(:qa_standard_types, :set_updated_at)
    drop_function(:qa_standard_types_set_updated_at)
    drop_table(:qa_standard_types)

    drop_trigger(:chemicals, :audit_trigger_row)
    drop_trigger(:chemicals, :audit_trigger_stm)

    drop_trigger(:chemicals, :set_created_at)
    drop_function(:chemicals_set_created_at)
    drop_trigger(:chemicals, :set_updated_at)
    drop_function(:chemicals_set_updated_at)
    drop_table(:chemicals)
  end
end
