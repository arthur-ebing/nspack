Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Depot Pallet Buildup', functional_area: 'RMD', program: 'Buildups', url: '/rmd/depot_buildups/depot_pallet_buildup', seq: 2
  end

  down do
    drop_program_function 'Depot Pallet Buildup', functional_area: 'RMD', program: 'Buildups'
  end
end
