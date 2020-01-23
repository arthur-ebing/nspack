Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'List Masterfile Variants', functional_area: 'Masterfiles', program: 'General', url: '/list/masterfile_variants', seq: 2
  end

  down do
    drop_program_function 'List Masterfile Variants', functional_area: 'Masterfiles', program: 'General'
  end
end
