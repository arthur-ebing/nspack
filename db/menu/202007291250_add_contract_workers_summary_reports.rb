Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Packers', functional_area: 'Production', program: 'Shifts', url: '/production/shifts/summary_reports/packers', group: 'Summary Reports', seq: 3
    add_program_function 'Palletizers', functional_area: 'Production', program: 'Shifts', url: '/production/shifts/summary_reports/palletizer', group: 'Summary Reports', seq: 4
  end

  down do
    drop_program_function 'Packers', functional_area: 'Production', program: 'Shifts', match_group: 'Summary Reports'
    drop_program_function 'Palletizers', functional_area: 'Production', program: 'Shifts', match_group: 'Summary Reports'
  end
end
