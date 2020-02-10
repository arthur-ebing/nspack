require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    create_table(:shift_types, ignore_index_errors: true) do
      primary_key :id
      foreign_key :plant_resource_id, :plant_resources, null: false, key: [:id] #(line or ph)
      foreign_key :employment_type_id, :employment_types, null: false, key: [:id]

      Integer :start_hour, null: false
      Integer :end_hour, null: false
      String :day_night_or_custom, null: false

      index [:plant_resource_id, :employment_type_id, :start_hour, :end_hour, :day_night_or_custom], name: :shift_types_all_round_unique, unique: true
    end
    # Validation hours can't overlap for plant_resource_id & employment_type_id combination
    # Delete and re-add (not editable)
    # fn_shift_type_code(shift_type_id)
    # resource_code (ph)+ resource_code (line)+ employment_type_code + D_N_C + start_hour + end_hour (FUNCTION)

    create_table(:shifts, ignore_index_errors: true) do
      primary_key :id
      foreign_key :shift_type_id, :shift_types, null: false, key: [:id]

      # TrueClass :other_bool, default: false
      TrueClass :active, default: true

      BigDecimal :running_hours, size: [4,2] #(start to end of shift type override)
      DateTime :start_date_time
      DateTime :end_date_time

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:shift_type_id], name: :fki_shifts_shift_types, unique: true
    end
    # Validation (Time slots can't overlap for same shift type)

    pgt_created_at(:shifts,
                   :created_at,
                   function_name: :shifts_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:shifts,
                   :updated_at,
                   function_name: :shifts_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('shifts', true, true, '{updated_at}'::text[]);"

    # SEARCH PARAMETERS
    # shift type
    # start time
    # worker

    # Parent Child relationship to shifts on grid (Standard edit view)
    create_table(:shift_exceptions, ignore_index_errors: true) do
      primary_key :id
      foreign_key :shift_id, :shifts, null: false, key: [:id]
      foreign_key :contract_worker_id, :contract_workers, null: false, key: [:id]

      String :remarks, text: true
      BigDecimal :running_hours, size: [4,2] # >0 (For one specific worker)

      # TrueClass :other_bool, default: false
      # TrueClass :active, default: true

      DateTime :start_date_time
      DateTime :end_date_time

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:contract_worker_id], name: :shift_exceptions_unique_contract_workers, unique: true
      index [:shift_id], name: :fki_shift_exceptions_shifts, unique: true
    end

    pgt_created_at(:shift_exceptions,
                   :created_at,
                   function_name: :shift_exceptions_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:shift_exceptions,
                   :updated_at,
                   function_name: :shift_exceptions_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('shift_exceptions', true, true, '{updated_at}'::text[]);"
  end

  down do
    # Drop logging for this table.
    drop_trigger(:shift_exceptions, :audit_trigger_row)
    drop_trigger(:shift_exceptions, :audit_trigger_stm)

    drop_trigger(:shift_exceptions, :set_created_at)
    drop_function(:shift_exceptions_set_created_at)
    drop_trigger(:shift_exceptions, :set_updated_at)
    drop_function(:shift_exceptions_set_updated_at)
    drop_table(:shift_exceptions)

    # Drop logging for this table.
    drop_trigger(:shifts, :audit_trigger_row)
    drop_trigger(:shifts, :audit_trigger_stm)

    drop_trigger(:shifts, :set_created_at)
    drop_function(:shifts_set_created_at)
    drop_trigger(:shifts, :set_updated_at)
    drop_function(:shifts_set_updated_at)
    drop_table(:shifts)
    drop_table(:shift_types)
  end
end
