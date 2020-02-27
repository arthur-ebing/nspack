Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Print Location Barcodes', functional_area: 'Masterfiles', program: 'Locations', url: '/list/locations/multi?key=locations', seq: 8
  end

  down do
    drop_program_function 'Print Location Barcodes', functional_area: 'Masterfiles', program: 'Locations'
  end
end
