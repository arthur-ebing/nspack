Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Scrap Reasons', functional_area: 'Masterfiles', program: 'Quality', url: '/list/scrap_reasons', seq: 2
  end

  down do
    drop_program_function 'Scrap Reasons', functional_area: 'Masterfiles', program: 'Quality'
  end
end
