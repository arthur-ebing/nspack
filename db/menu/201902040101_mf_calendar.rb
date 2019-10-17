Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Calendar', functional_area: 'Masterfiles'
    add_program_function 'Season_groups', functional_area: 'Masterfiles', program: 'Calendar', url: '/list/season_groups'
    add_program_function 'Seasons', functional_area: 'Masterfiles', program: 'Calendar', url: '/list/seasons'
  end

  down do
    drop_program 'Calendar', functional_area: 'Masterfiles'
  end
end
