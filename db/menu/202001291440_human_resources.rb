Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'HR', functional_area: 'Masterfiles', seq: 1
    add_program_function 'Employment Types', functional_area: 'Masterfiles', program: 'HR', url: '/list/employment_types', seq: 2
    add_program_function 'Contract Types', functional_area: 'Masterfiles', program: 'HR', url: '/list/contract_types', seq: 3
    add_program_function 'Wage Levels', functional_area: 'Masterfiles', program: 'HR', url: '/list/wage_levels', seq: 4
  end

  down do
    drop_program 'HR', functional_area: 'Masterfiles'
  end
end
