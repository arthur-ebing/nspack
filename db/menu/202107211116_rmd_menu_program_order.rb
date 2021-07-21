Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program 'Home', functional_area: 'RMD', seq: 1
    change_program 'Raw Material', functional_area: 'RMD', seq: 2
    change_program 'Production', functional_area: 'RMD', seq: 3
    change_program 'Pallet Verification', functional_area: 'RMD', seq: 4
    change_program 'Buildups', functional_area: 'RMD', seq: 5
    change_program 'Finished Goods', functional_area: 'RMD', seq: 6
    change_program 'Robot functions', functional_area: 'RMD', seq: 7
    change_program 'Utilities', functional_area: 'RMD', seq: 8
  end

  down do
    change_program 'Home', functional_area: 'RMD', seq: 1
    change_program 'Raw Material', functional_area: 'RMD', seq: 1
    change_program 'Production', functional_area: 'RMD', seq: 1
    change_program 'Pallet Verification', functional_area: 'RMD', seq: 1
    change_program 'Buildups', functional_area: 'RMD', seq: 1
    change_program 'Finished Goods', functional_area: 'RMD', seq: 1
    change_program 'Robot functions', functional_area: 'RMD', seq: 1
    change_program 'Utilities', functional_area: 'RMD', seq: 1
  end
end
