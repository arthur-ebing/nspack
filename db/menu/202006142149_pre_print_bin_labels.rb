Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Preprint Bin Labels', functional_area: 'Raw Materials', program: 'Deliveries', url: '/raw_materials/deliveries/pre_print_bin_labels', seq: 8
  end

  down do
    drop_program_function 'Preprint Bin Labels', functional_area: 'Raw Materials', program: 'Deliveries'
  end
end
