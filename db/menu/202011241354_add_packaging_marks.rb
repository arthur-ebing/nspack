Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'PM Marks', functional_area: 'Masterfiles', program: 'Packaging', url: '/list/pm_marks', seq: 13, group: 'Bill of Materials'
  end

  down do
    drop_program_function 'PM Marks', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials'
  end
end
