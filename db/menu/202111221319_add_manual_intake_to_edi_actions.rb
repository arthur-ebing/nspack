Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Manual Intake', functional_area: 'EDI', program: 'Actions', url: '/list/edi_in_transactions/with_params?key=manual_intakes', seq: 2
  end

  down do
    drop_program_function 'Manual Intake', functional_area: 'EDI', program: 'Actions'
  end
end
