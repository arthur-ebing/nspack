require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    alter_table(:commodities) do
      add_column :color_applies, TrueClass, default: false
    end

    create_table(:color_percentages , ignore_index_errors: true) do
      primary_key :id
      foreign_key :commodity_id, :commodities, type: :integer, null: false
      Integer :color_percentage
      String :description, null: false
      TrueClass :active, null: false, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:description, :commodity_id], name: :color_percentage_unique_code, unique: true
    end

    pgt_created_at(:color_percentages,
                   :created_at,
                   function_name: :color_percentages_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:color_percentages,
                   :updated_at,
                   function_name: :color_percentages_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('color_percentages', true, true, '{updated_at}'::text[]);"

    alter_table(:product_setups) do
      add_foreign_key :color_percentage_id, :color_percentages, null: true, key: [:id]
    end

    alter_table(:carton_labels) do
      add_foreign_key :color_percentage_id, :color_percentages, null: true, key: [:id]
    end

    alter_table(:pallet_sequences) do
      add_foreign_key :color_percentage_id, :color_percentages, null: true, key: [:id]
    end
  end

  down do
    alter_table(:product_setups) do
      drop_column :color_percentage_id
    end

    alter_table(:carton_labels) do
      drop_column :color_percentage_id
    end

    alter_table(:pallet_sequences) do
      drop_column :color_percentage_id
    end

    alter_table(:commodities) do
      drop_column :color_applies
    end

    drop_trigger(:color_percentages, :audit_trigger_row)
    drop_trigger(:color_percentages, :audit_trigger_stm)

    drop_trigger(:color_percentages, :set_created_at)
    drop_function(:color_percentages_set_created_at)
    drop_trigger(:color_percentages, :set_updated_at)
    drop_function(:color_percentages_set_updated_at)
    drop_table :color_percentages
  end
end
