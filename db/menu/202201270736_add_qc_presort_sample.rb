Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New Presort QC Sample', functional_area: 'Quality', program: 'Qc', url: '/quality/qc/qc_samples/new_presort_sample', seq: 4
  end

  down do
    drop_program_function 'New Presort QC Sample', functional_area: 'Quality', program: 'Qc'
  end
end
