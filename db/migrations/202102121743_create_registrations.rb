require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:registrations, ignore_index_errors: true) do
      primary_key :id
      foreign_key :party_role_id, :party_roles, type: :integer, null: false
      String :registration_type, null: false
      String :registration_code, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:party_role_id, :registration_type], name: :registrations_unique_code, unique: true
    end

    pgt_created_at(:registrations,
                   :created_at,
                   function_name: :registrations_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:registrations,
                   :updated_at,
                   function_name: :registrations_set_updated_at,
                   trigger_name: :set_updated_at)
  end

  down do
    drop_trigger(:registrations, :set_updated_at)
    drop_function(:registrations_set_updated_at)
    drop_trigger(:registrations, :set_created_at)
    drop_function(:registrations_set_created_at)
    drop_table(:registrations)
  end
end
