Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'HR', functional_area: 'Masterfiles', seq: 1
    add_program_function 'Employment Types', functional_area: 'Masterfiles', program: 'HR', url: '/list/employment_types', seq: 2, group: 'Contract Workers'
    add_program_function 'Contract Types', functional_area: 'Masterfiles', program: 'HR', url: '/list/contract_types', seq: 3, group: 'Contract Workers'
    add_program_function 'Wage Levels', functional_area: 'Masterfiles', program: 'HR', url: '/list/wage_levels', seq: 4, group: 'Contract Workers'
    add_program_function 'Contract Workers', functional_area: 'Masterfiles', program: 'HR', url: '/list/contract_workers', seq: 5, group: 'Contract Workers'
    add_program_function 'Search Contract Workers', functional_area: 'Masterfiles', program: 'HR', url: '/search/contract_workers', seq: 6, group: 'Contract Workers'
  end

  down do
    drop_program 'HR', functional_area: 'Masterfiles'
  end
end
