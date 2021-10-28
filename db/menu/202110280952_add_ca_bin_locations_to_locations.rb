Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Locations', functional_area: 'Raw Materials', seq: 7
    add_program_function 'CA Treatment Bins', functional_area: 'Raw Materials', program: 'Locations', url: '/list/ca_bin_locations'
  end

  down do
    drop_program 'Locations', functional_area: 'Raw Materials'
  end
end
