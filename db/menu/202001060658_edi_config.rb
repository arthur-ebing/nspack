Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Config', functional_area: 'EDI', seq: 2
    add_program_function 'OUT rules', functional_area: 'EDI', program: 'Config', url: '/list/edi_out_rules'
  end

  down do
    drop_program 'Config', functional_area: 'EDI'
  end
end
