Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    # add_program_function 'New Mrl Requirement', functional_area: 'Masterfiles', program: 'Quality', url: '/masterfiles/quality/mrl_requirements/new', seq: 18, group: 'MRL'
    add_program_function 'MRL Requirements', functional_area: 'Masterfiles', program: 'Quality', url: '/list/mrl_requirements', seq: 19, group: 'MRL'
    # add_program_function 'Search Mrl Requirements', functional_area: 'Masterfiles', program: 'Quality', url: '/search/mrl_requirements', seq: 20, group: 'MRL'
  end

  down do
    # drop_program_function 'Search Mrl Requirements', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'
    drop_program_function 'MRL Requirements', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'
    # drop_program_function 'New Mrl Requirement', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'
  end
end
