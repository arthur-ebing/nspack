Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'External Masterfile Mappings',
                            functional_area: 'Masterfiles',
                            program: 'General',
                            rename: 'Masterfile Transformations',
                            url: '/masterfiles/general/masterfile_transformations/list',
                            seq: 3
    change_program_function 'List Masterfile Variants',
                            functional_area: 'Masterfiles',
                            program: 'General',
                            rename: 'Masterfile Variants'
  end

  down do
    change_program_function 'Masterfile Transformations',
                            functional_area: 'Masterfiles',
                            program: 'General',
                            rename: 'External Masterfile Mappings',
                            url: '/masterfiles/general/external_masterfile_mappings/list',
                            seq: 3
    change_program_function 'Masterfile Variants',
                            functional_area: 'Masterfiles',
                            program: 'General',
                            rename: 'List Masterfile Variants'
  end
end
