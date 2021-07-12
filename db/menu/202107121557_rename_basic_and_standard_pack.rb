Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Basic', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Pack codes', rename: 'Basic Packs'
    change_program_function 'Standard', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Pack codes', rename: 'Standard Packs'
  end

  down do
    change_program_function 'Basic Packs', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Pack codes', rename: 'Basic'
    change_program_function 'Standard Packs', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Pack codes', rename: 'Standard'
  end
end
