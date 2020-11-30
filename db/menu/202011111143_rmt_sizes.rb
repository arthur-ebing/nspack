Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'List Rmt Sizes', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/rmt_sizes', seq: 2
  end

  down do
    drop_program_function 'List Rmt Sizes', functional_area: 'Masterfiles', program: 'Raw Materials'
  end
end