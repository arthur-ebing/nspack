Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    # add_program 'QA', functional_area: 'Masterfiles'
    add_program_function 'Chemicals', functional_area: 'Masterfiles', program: 'Quality', url: '/list/chemicals', seq: 15, group: 'MRL'
    add_program_function 'QA Standards', functional_area: 'Masterfiles', program: 'Quality', url: '/list/qa_standards', seq: 16, group: 'MRL'
    add_program_function 'QA Standard Types', functional_area: 'Masterfiles', program: 'Quality', url: '/list/qa_standard_types', seq: 17, group: 'MRL'
  end

  down do
    # drop_program 'QA', functional_area: 'Masterfiles'
    drop_program_function 'Chemicals', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'
    drop_program_function 'QA Standard Types', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'
    drop_program_function 'QA Standards', functional_area: 'Masterfiles', program: 'Quality', match_group: 'MRL'
  end
end
