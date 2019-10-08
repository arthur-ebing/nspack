
require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:seasons) do
      set_column_not_null :season_year
      set_column_not_null :start_date
      set_column_not_null :end_date
    end
  end

  down do
    alter_table(:seasons) do
      set_column_allow_null :season_year
      set_column_allow_null :start_date
      set_column_allow_null :end_date
    end
  end
end
