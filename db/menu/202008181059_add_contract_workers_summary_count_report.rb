Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Packers Count', functional_area: 'Production', program: 'Shifts', url: '/production/shifts/summary_reports/packer_count', group: 'Summary Reports', seq: 5
  end

  down do
    drop_program_function 'Packers Count', functional_area: 'Production', program: 'Shifts', match_group: 'Summary Reports'
  end
end
