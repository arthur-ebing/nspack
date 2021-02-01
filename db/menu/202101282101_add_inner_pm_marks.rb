Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Inner PM Marks', functional_area: 'Masterfiles', program: 'Packaging', url: '/list/inner_pm_marks', seq: 14, group: 'Bill of Materials'
  end

  down do
    drop_program_function 'Inner PM Marks', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials'
  end
end
