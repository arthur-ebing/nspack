Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'QC', functional_area: 'Quality', seq: 1
    # add_program_function 'Select QC Sample', functional_area: 'Quality', program: 'QC', url: '/quality/qc/qc_samples/select', seq: 1
    add_program_function 'Incomplete QC Samples', functional_area: 'Quality', program: 'QC', url: '/list/qc_samples/with_params?key=incomplete', seq: 2
    add_program_function 'Search QC Samples', functional_area: 'Quality', program: 'Qc', url: '/search/qc_samples', seq: 3
    # add_program_function 'Starch', functional_area: 'Quality', program: 'Qc', group: 'Test', url: '/quality/qc/qc_samples/select/starch', seq: 4
  end

  down do
    drop_program 'QC', functional_area: 'Quality'
  end
end
