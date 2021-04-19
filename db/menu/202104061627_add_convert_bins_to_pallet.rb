Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Convert Bins To Pallets', functional_area: 'RMD', program: 'Raw Material', url: '/rmd/raw_materials/convert_bins_to_pallets', seq: 9
  end

  down do
    drop_program_function 'Convert Bins To Pallets', functional_area: 'RMD', program: 'Raw Material'
  end
end