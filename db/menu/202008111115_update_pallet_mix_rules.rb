Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Global Pallet Mix Rule', rename: 'Pallet Mix Rule', functional_area: 'Production', program: 'Runs', url: '/list/pallet_mix_rules', seq: 6
  end

  down do
    change_program_function 'Pallet Mix Rule', rename: 'Global Pallet Mix Rule', functional_area: 'Production', program: 'Runs', url: '/production/runs/mix_pallet_rules/global', seq: 6
  end
end
