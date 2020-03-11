Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'New', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', restricted: true
    change_program_function 'List', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', restricted: true
  end

  down do
    change_program_function 'New', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', restricted: false
    change_program_function 'List', match_group: 'Scrap Pallet', functional_area: 'Production', program: 'Reworks', restricted: false
  end
end
