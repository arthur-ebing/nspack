Sequel.migration do
  up do
    alter_table(:loads) do
      add_column :loaded, :boolean, default: false
      add_column :requires_temp_tail, :boolean, default: false
    end

    run <<~SQL
      UPDATE loads
      SET loaded = true
      WHERE shipped
    SQL
    run <<~SQL
      UPDATE loads
      SET requires_temp_tail = true
      WHERE id in (select distinct load_id from pallets where temp_tail is not null and load_id is not null)
    SQL


  end

  down do
    alter_table(:loads) do
      drop_column :requires_temp_tail
      drop_column :loaded
    end
  end
end
