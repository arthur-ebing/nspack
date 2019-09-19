require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    extension :pg_json

    create_table(:labels) do
      primary_key :id
      String :label_name, null: false
      String :label_json, text: true
      String :label_dimension, null: false
      String :variable_xml, text: true
      String :px_per_mm, null: false, default: '8'
      File :png_image
      Jsonb :sample_data
      String :variable_set, null: false
      Jsonb :extended_columns
      TrueClass :multi_label, default: false
      TrueClass :completed, default: false
      TrueClass :approved, default: false
      TrueClass :active, default: true
      String :created_by
      String :updated_by
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:label_name], name: :labels_unique_label_name, unique: true
    end


    pgt_created_at(:labels,
                   :created_at,
                   function_name: :labels_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:labels,
                   :updated_at,
                   function_name: :labels_set_updated_at,
                   trigger_name: :set_updated_at)

    run "SELECT audit.audit_table('labels', 'true', 'true', '{sample_data, updated_at}'::text[]);"

    run 'CREATE EXTENSION IF NOT EXISTS citext;'
    alter_table(:labels) do
      set_column_type :label_name, :citext
    end
  end

  down do
    drop_trigger(:labels, :audit_trigger_row)
    drop_trigger(:labels, :audit_trigger_stm)

    drop_trigger(:labels, :set_created_at)
    drop_function(:labels_set_created_at)
    drop_trigger(:labels, :set_updated_at)
    drop_function(:labels_set_updated_at)
    drop_table(:labels)
  end
end
