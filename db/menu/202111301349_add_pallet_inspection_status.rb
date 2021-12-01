Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Pallet Inspection Status', functional_area: 'Finished Goods', program: 'Inspection', url: '/finished_goods/inspection/inspections/pallet_inspection_status', seq: 4
  end

  down do
    drop_program_function 'Pallet Inspection Status', functional_area: 'Finished Goods', program: 'Inspection'
  end
end
