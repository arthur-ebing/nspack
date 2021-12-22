Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Laboratories', functional_area: 'Masterfiles', program: 'Quality', url: '/list/laboratories', seq: 13, group: 'MRL'
    add_program_function 'Sample Types', functional_area: 'Masterfiles', program: 'Quality', url: '/list/mrl_sample_types', seq: 14, group: 'MRL'

    add_program 'MRL', functional_area: 'Quality', seq: 1
    add_program_function 'List Results', functional_area: 'Quality', program: 'MRL', url: '/list/mrl_results', seq: 1
  end

  down do
    drop_program_function 'Laboratories', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'
    drop_program_function 'Sample Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'

    drop_program 'MRL', functional_area: 'Quality'
  end
end
