require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    alter_table(:commodities) do
      rename_column :color_applies, :colour_applies
    end

    alter_table(:product_setups) do
      rename_column :color_percentage_id, :colour_percentage_id
    end

    alter_table(:carton_labels) do
      rename_column :color_percentage_id, :colour_percentage_id
    end

    alter_table(:pallet_sequences) do
      rename_column :color_percentage_id, :colour_percentage_id
    end

    alter_table(:color_percentages) do
      rename_column :color_percentage, :colour_percentage
    end

    drop_trigger(:color_percentages, :audit_trigger_row)
    drop_trigger(:color_percentages, :audit_trigger_stm)

    drop_trigger(:color_percentages, :set_created_at)
    drop_function(:color_percentages_set_created_at)
    drop_trigger(:color_percentages, :set_updated_at)
    drop_function(:color_percentages_set_updated_at)

    rename_table(:color_percentages, :colour_percentages)
    pgt_created_at(:colour_percentages,
                   :created_at,
                   function_name: :colour_percentages_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:colour_percentages,
                   :updated_at,
                   function_name: :colour_percentages_set_updated_at,
                   trigger_name: :set_updated_at)

    run "SELECT audit.audit_table('colour_percentages', true, true, '{updated_at}'::text[]);"
  end

  down do
    alter_table(:commodities) do
      rename_column :colour_applies, :color_applies
    end

    alter_table(:product_setups) do
      rename_column :colour_percentage_id, :color_percentage_id
    end

    alter_table(:carton_labels) do
      rename_column :colour_percentage_id, :color_percentage_id
    end

    alter_table(:pallet_sequences) do
      rename_column :colour_percentage_id, :color_percentage_id
    end

    drop_trigger(:colour_percentages, :audit_trigger_row)
    drop_trigger(:colour_percentages, :audit_trigger_stm)

    drop_trigger(:colour_percentages, :set_created_at)
    drop_function(:colour_percentages_set_created_at)
    drop_trigger(:colour_percentages, :set_updated_at)
    drop_function(:colour_percentages_set_updated_at)

    rename_table(:colour_percentages, :color_percentages)

    alter_table(:color_percentages) do
      rename_column :colour_percentage, :color_percentage
    end

    pgt_created_at(:color_percentages,
                   :created_at,
                   function_name: :color_percentages_set_created_at,
                   trigger_name: :set_created_at)

    pgt_updated_at(:color_percentages,
                   :updated_at,
                   function_name: :color_percentages_set_updated_at,
                   trigger_name: :set_updated_at)

    run "SELECT audit.audit_table('color_percentages', true, true, '{updated_at}'::text[]);"
  end
end
