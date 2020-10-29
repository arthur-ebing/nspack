require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:pm_composition_levels, ignore_index_errors: true) do
      primary_key :id
      Integer :composition_level, null: false
      String :description, null: false
      TrueClass :active, default: true
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:description], name: :pm_composition_level_unique_code, unique: true
    end

    pgt_created_at(:pm_composition_levels,
                   :created_at,
                   function_name: :pm_composition_levels_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:pm_composition_levels,
                   :updated_at,
                   function_name: :pm_composition_levels_set_updated_at,
                   trigger_name: :set_updated_at)

    # Log changes to this table. Exclude changes to the updated_at column.
    run "SELECT audit.audit_table('pm_composition_levels', true, true, '{updated_at}'::text[]);"

    alter_table(:pm_types) do
      add_foreign_key :pm_composition_level_id, :pm_composition_levels
    end

    alter_table(:pm_boms) do
      add_column :system_code, String
    end

    alter_table(:pm_products) do
      add_column :material_mass, Numeric
      add_column :height_mm, Integer
      add_foreign_key :basic_pack_id, :basic_pack_codes
    end

  end

  down do
    alter_table(:pm_types) do
      drop_column :pm_composition_level_id
    end

    alter_table(:pm_boms) do
      drop_column :system_code
    end

    alter_table(:pm_products) do
      drop_column :material_mass
      drop_column :height_mm
      drop_column :basic_pack_id
    end

    # Drop logging for this table.
    drop_trigger(:pm_composition_levels, :audit_trigger_row)
    drop_trigger(:pm_composition_levels, :audit_trigger_stm)

    drop_trigger(:pm_composition_levels, :set_created_at)
    drop_function(:pm_composition_levels_set_created_at)
    drop_trigger(:pm_composition_levels, :set_updated_at)
    drop_function(:pm_composition_levels_set_updated_at)
    drop_table(:pm_composition_levels)
  end
end
