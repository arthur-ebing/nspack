Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    drop_program_function 'New', functional_area: 'EDI', program: 'Config'
  end

  down do
    add_program_function 'New', functional_area: 'EDI', program: 'Config', url: '/edi/config/edi_out_rules', seq: 2
  end
end
