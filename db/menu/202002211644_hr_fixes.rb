Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Employment Types', functional_area: 'Masterfiles', program: 'HR', match_group: 'Contract Workers', group: 'Contract Worker Config'
    change_program_function 'Contract Types', functional_area: 'Masterfiles', program: 'HR', match_group: 'Contract Workers', group: 'Contract Worker Config'
    change_program_function 'Wage Levels', functional_area: 'Masterfiles', program: 'HR', match_group: 'Contract Workers', group: 'Contract Worker Config'
  end

  down do
    change_program_function 'Employment Types', functional_area: 'Masterfiles', program: 'HR', match_group: 'Contract Worker Config', group: 'Contract Workers'
    change_program_function 'Contract Types', functional_area: 'Masterfiles', program: 'HR', match_group: 'Contract Worker Config', group: 'Contract Workers'
    change_program_function 'Wage Levels', functional_area: 'Masterfiles', program: 'HR', match_group: 'Contract Worker Config', group: 'Contract Workers'
  end
end



