Sequel.migration do
  up do
    alter_table(:load_containers) do
      set_column_type :container_temperature_rhine, String
      set_column_type :container_temperature_rhine2, String
    end
  end

  down do
    # NB: the conversion back from string to int needs to be done in SQL with the USING clause:
    run <<~SQL
      ALTER TABLE load_containers ALTER COLUMN container_temperature_rhine TYPE numeric USING (trim(container_temperature_rhine)::numeric);
      ALTER TABLE load_containers ALTER COLUMN container_temperature_rhine2 TYPE numeric USING (trim(container_temperature_rhine2)::numeric);
    SQL
  end
end
