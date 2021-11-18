Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Bin Enquiry', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/raw_materials/bin_enquiry/scan_bin'
  end

  down do
    drop_program_function 'Bin Enquiry', functional_area: 'RMD', program: 'Raw Material'
  end
end
