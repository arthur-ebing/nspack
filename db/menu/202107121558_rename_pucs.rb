Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Pucs', functional_area: 'Masterfiles', program: 'Farms', rename: 'PUCs'
    change_program_function 'Rmt Container Types', functional_area: 'Masterfiles', program: 'Farms', rename: 'RMT Container Types'
    change_program_function 'Rmt Container Material Types', functional_area: 'Masterfiles', program: 'Farms', rename: 'RMT Container Material Types'
  end

  down do
    change_program_function 'PUCs', functional_area: 'Masterfiles', program: 'Farms', rename: 'Pucs'
    change_program_function 'RMT Container Types', functional_area: 'Masterfiles', program: 'Farms', rename: 'Rmt Container Types'
    change_program_function 'RMT Container Material Types', functional_area: 'Masterfiles', program: 'Farms', rename: 'Rmt Container Material Types'
  end
end
