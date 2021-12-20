Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Scrap Reasons', functional_area: 'Masterfiles', program: 'Quality', group: 'Inspections'
    change_program_function 'Pallet Verification Failure Reasons', functional_area: 'Masterfiles', program: 'Quality', group: 'Inspections'
    change_program_function 'Inspection Types', functional_area: 'Masterfiles', program: 'Quality', group: 'Inspections'
    change_program_function 'Inspectors', functional_area: 'Masterfiles', program: 'Quality', group: 'Inspections'
    change_program_function 'Inspection Failure Reasons', functional_area: 'Masterfiles', program: 'Quality', group: 'Inspections'
    change_program_function 'Inspection Failure Types', functional_area: 'Masterfiles', program: 'Quality', group: 'Inspections'

    drop_program_function 'Test Types', functional_area: 'Quality', program: 'Config'
    drop_program 'Config', functional_area: 'Quality'
    add_program_function 'Test Types', functional_area: 'Masterfiles', program: 'Quality', group: 'OTMC', url: '/list/orchard_test_types', seq: 1

    change_program 'Test Results', functional_area: 'Quality', rename: 'OTMC'
  end

  down do
    change_program_function 'Scrap Reasons', functional_area: 'Masterfiles', program: 'Quality', match_group: 'Inspections', group: nil
    change_program_function 'Pallet Verification Failure Reasons', functional_area: 'Masterfiles', program: 'Quality', match_group: 'Inspections', group: nil
    change_program_function 'Inspection Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'Inspections', group: nil
    change_program_function 'Inspectors', functional_area: 'Masterfiles', program: 'Quality', match_group: 'Inspections', group: nil
    change_program_function 'Inspection Failure Reasons', functional_area: 'Masterfiles', program: 'Quality', match_group: 'Inspections', group: nil
    change_program_function 'Inspection Failure Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'Inspections', group: nil

    change_program 'OTMC', functional_area: 'Quality', rename: 'Test Results'

    drop_program_function 'Test Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'OTMC'
    add_program 'Config', functional_area: 'Quality'
    add_program_function 'Test Types', functional_area: 'Quality', program: 'Config', url: '/list/orchard_test_types', seq: 1
  end
end
