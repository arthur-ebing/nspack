Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/recalc_nett_weight/new', group: 'Recalc Nett Weight', seq: 10
    add_program_function 'List', functional_area: 'Production', program: 'Reworks', url: '/production/reworks/reworks_runs/recalc_nett_weight', group: 'Recalc Nett Weight', seq: 11
  end

  down do
    drop_program_function 'New', functional_area: 'Production', program: 'Reworks'
    drop_program_function 'List', functional_area: 'Production', program: 'Reworks'
  end
end
