Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'External Masterfile Mappings', functional_area: 'Masterfiles', program: 'General', url: '/masterfiles/general/external_masterfile_mappings/list', seq: 3
  end

  down do
    drop_program_function 'External Masterfile Mappings', functional_area: 'Masterfiles', program: 'General'
  end
end
