Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Offload Vehicle', functional_area: 'RMD', program: 'Finished Goods', url: '/rmd/finished_goods/offload_vehicle', seq: 5
  end

  down do
    drop_program_function 'Offload Vehicle', functional_area: 'RMD', program: 'Finished Goods'
  end
end
