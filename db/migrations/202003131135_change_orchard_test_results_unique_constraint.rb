# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    drop_index :orchard_test_results, [:orchard_test_type_id, :orchard_id], name: :orchard_test_type_orchard_unique_code
    alter_table(:orchard_test_results) do
      add_index [:orchard_test_type_id, :puc_id, :orchard_id, :cultivar_id], name: :orchard_test_type_orchard_unique_code, unique: true
    end
    run <<~SQL
      alter table orchard_test_results alter column puc_id set not null;
      alter table orchard_test_results alter column orchard_id set not null;
      alter table orchard_test_results alter column cultivar_id set not null;
    SQL
  end

  down do
    run <<~SQL
      alter table orchard_test_results alter column puc_id drop not null;
      alter table orchard_test_results alter column orchard_id drop not null;
      alter table orchard_test_results alter column cultivar_id drop not null;
    SQL
  end
end
