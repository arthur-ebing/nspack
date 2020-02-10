Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Scrapped', functional_area: 'Lists', program: 'Bins', url: '/list/scrapped_rmt_bins', seq: 5
  end

  down do
    drop_program_function 'Scrapped', functional_area: 'Lists', program: 'Bins'
  end
end
