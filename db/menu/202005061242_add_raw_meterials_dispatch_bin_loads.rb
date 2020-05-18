Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Dispatch', functional_area: 'Raw Materials', seq: 1
    add_program_function 'List Bin Load Purposes', functional_area: 'Raw Materials', program: 'Dispatch', url: '/list/bin_load_purposes', seq: 1
    add_program_function 'List Bin Loads', functional_area: 'Raw Materials', program: 'Dispatch', url: '/list/bin_loads', seq: 2
  end

  down do
    drop_program 'Dispatch', functional_area: 'Raw Materials'
  end
end