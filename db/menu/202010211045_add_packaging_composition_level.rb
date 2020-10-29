Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Composition Level', functional_area: 'Masterfiles', program: 'Packaging', url: '/list/pm_composition_levels', seq: 7, group: 'Bill of Materials'
  end

  down do
    drop_program_function 'Composition Level', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials'
  end
end
