Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'List Masterfile Variants', functional_area: 'Masterfiles', program: 'General', url: '/masterfiles/general/masterfile_variants/list_masterfile_variants', seq: 2
  end

  down do
    change_program_function 'List Masterfile Variants', functional_area: 'Masterfiles', program: 'General', url: '/list/masterfile_variants', seq: 2
  end
end
