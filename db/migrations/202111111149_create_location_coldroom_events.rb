require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:location_coldroom_events, ignore_index_errors: true) do
      primary_key :id
      foreign_key :location_id, :locations, null: false
      String :event_name, null: false
      DateTime :created_at, null: false

      index [:location_id], name: :fki_location_coldroom_events_locations
    end

    pgt_created_at(:location_coldroom_events,
                   :created_at,
                   function_name: :pgt_location_coldroom_events_set_created_at,
                   trigger_name: :set_created_at)

    alter_table(:rmt_bins) do
      add_column :coldroom_events, 'integer[]', default: '{}'
    end
  end

  down do
    drop_trigger(:location_coldroom_events, :set_created_at)
    drop_function(:pgt_location_coldroom_events_set_created_at)
    drop_table(:location_coldroom_events)

    alter_table(:rmt_bins) do
      drop_column :coldroom_events
    end
  end
end
