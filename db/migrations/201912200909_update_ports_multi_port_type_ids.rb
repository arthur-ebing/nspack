Sequel.migration do
  up do
    alter_table(:ports) do
      add_column :port_type_ids, 'integer[]'
      add_column :voyage_type_ids, 'integer[]'
    end

    run <<~SQL
      UPDATE ports
      SET port_type_ids = ARRAY[port_type_id],
          voyage_type_ids = ARRAY[voyage_type_id];
    SQL

    alter_table(:voyage_ports) do
      add_foreign_key :port_type_id, :port_types, type: :integer
    end

    run <<~SQL
    UPDATE voyage_ports 
       SET port_type_id = (SELECT port_type_id from ports WHERE ports.id = voyage_ports.port_id)
    SQL

    run <<~SQL
      ALTER TABLE voyage_ports
          ALTER COLUMN port_type_id SET NOT NULL;
    SQL

    alter_table(:ports) do
      drop_column :voyage_type_id
      drop_column :port_type_id
    end
  end

  down do
    alter_table(:voyage_ports) do
      drop_foreign_key :port_type_id
    end

    alter_table(:ports) do
      add_foreign_key :port_type_id, :port_types, type: :integer
      add_foreign_key :voyage_type_id, :voyage_types, type: :integer
    end

    run <<~SQL
      UPDATE ports
      SET port_type_id = port_type_ids[1],
          voyage_type_id = voyage_type_ids[1];
    SQL

    run <<~SQL
      ALTER TABLE ports
          ALTER COLUMN port_type_id SET NOT NULL,
          ALTER COLUMN voyage_type_id SET NOT NULL;
    SQL

    alter_table(:ports) do
      drop_column :voyage_type_ids
      drop_column :port_type_ids
    end
  end
end
