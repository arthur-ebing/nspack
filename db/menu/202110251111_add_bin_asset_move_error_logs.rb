Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Bin Asset Move Error Logs', functional_area: 'Raw Materials', program: 'Bin Assets', url: '/list/bin_asset_move_error_logs', seq: 4
  end

  down do
    drop_program_function 'Bin Asset Move Error Logs', functional_area: 'Raw Materials', program: 'Bin Assets'
  end
end
