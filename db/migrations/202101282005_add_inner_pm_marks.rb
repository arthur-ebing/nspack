require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers
    create_table(:inner_pm_marks, ignore_index_errors: true) do
      primary_key :id
      String :inner_pm_mark_code, null: false
      String :description, null: false
      TrueClass :tu_mark, default: true
      TrueClass :ri_mark, default: true
      TrueClass :ru_mark, default: true

      index [:inner_pm_mark_code], name: :inner_pm_mark_unique_fruitspec_mark, unique: true
    end
  end
end
