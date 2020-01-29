Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Received errors', functional_area: 'EDI', program: 'Viewer', group: 'Received', url: '/edi/viewer/received/errors', seq: 6
    change_program_function 'Search received by name', functional_area: 'EDI', program: 'Viewer', match_group: 'Received', seq: 7
    change_program_function 'Search received by content', functional_area: 'EDI', program: 'Viewer', match_group: 'Received', seq: 8
  end

  down do
    drop_program_function 'Received errors', functional_area: 'EDI', program: 'Viewer', match_group: 'Received'
    change_program_function 'Search received by name', functional_area: 'EDI', program: 'Viewer', match_group: 'Received', seq: 6
    change_program_function 'Search received by content', functional_area: 'EDI', program: 'Viewer', match_group: 'Received', seq: 7
  end
end
