Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Global', functional_area: 'Production', program: 'Runs', url: '/production/runs/mix_pallet_rules/global', seq: 6
  end

  down do
    drop_program_function 'Global', functional_area: 'Production', program: 'Runs'
  end
end
