Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'EDI', program: 'Config', url: '/edi/config/edi_out_rules', seq: 2
  end

  down do
    drop_program_function 'New', functional_area: 'EDI', program: 'Config'
  end
end
