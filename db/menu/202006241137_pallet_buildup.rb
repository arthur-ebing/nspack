Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Buildups', functional_area: 'RMD'
    add_program_function 'Pallet Buildup', functional_area: 'RMD', program: 'Buildups', url: '/rmd/buildups/pallet_buildup', seq: 1
  end

  down do
    drop_program 'Buildups', functional_area: 'RMD'
    drop_program_function 'Pallet Buildup', functional_area: 'RMD', program: 'Buildups'
  end
end
