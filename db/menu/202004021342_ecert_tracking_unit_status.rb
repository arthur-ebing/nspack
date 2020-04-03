Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'eCert Tracking Unit Status', functional_area: 'Finished Goods', program: 'eCert', url: '/finished_goods/ecert/ecert_tracking_units/status', seq: 6
  end

  down do
    drop_program_function 'eCert Tracking Unit Status', functional_area: 'Finished Goods', program: 'eCert'
  end
end
