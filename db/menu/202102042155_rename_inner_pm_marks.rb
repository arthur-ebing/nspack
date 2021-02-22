Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'Inner PM Marks', rename: 'Inner PKG Marks', functional_area: 'Masterfiles', program: 'Packaging', seq: 14, group: 'Bill of Materials', match_group: 'Bill of Materials'
  end

  down do
    change_program_function 'Inner PKG Marks', rename: 'Inner PM Marks', functional_area: 'Masterfiles', program: 'Packaging', seq: 14, group: 'Bill of Materials', match_group: 'Bill of Materials'
  end
end
