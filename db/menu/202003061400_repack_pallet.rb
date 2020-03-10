Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
   add_program_function 'Repack Pallet', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/repack_pallet/scan_pallet', seq: 2
  end

  down do
    drop_program_function 'Repack Pallet', functional_area: 'RMD', program: 'Finished Goods'
  end
end
