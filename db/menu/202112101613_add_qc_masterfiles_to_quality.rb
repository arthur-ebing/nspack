Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'QC Measurement Types', functional_area: 'Masterfiles', program: 'Quality', group: 'QC', url: '/list/qc_measurement_types', seq: 1
    add_program_function 'QC Sample Types', functional_area: 'Masterfiles', program: 'Quality', group: 'QC', url: '/list/qc_sample_types', seq: 2
    add_program_function 'QC Test Types', functional_area: 'Masterfiles', program: 'Quality', group: 'QC', url: '/list/qc_test_types', seq: 3
    add_program_function 'Fruit Defect Types', functional_area: 'Masterfiles', program: 'Quality', group: 'QC', url: '/list/fruit_defect_types', seq: 5
    add_program_function 'Fruit Defects', functional_area: 'Masterfiles', program: 'Quality', group: 'QC', url: '/list/fruit_defects', seq: 6
  end

  down do
    drop_program_function 'Fruit Defects', functional_area: 'Masterfiles', program: 'Quality', match_group: 'QC'
    drop_program_function 'Fruit Defect Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'QC'
    drop_program_function 'QC Test Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'QC'
    drop_program_function 'QC Sample Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'QC'
    drop_program_function 'QC Measurement Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'QC'
  end
end
