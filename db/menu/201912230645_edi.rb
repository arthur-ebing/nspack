Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_functional_area 'EDI'
    add_program 'Viewer', functional_area: 'EDI'
    add_program_function 'Upload a file', functional_area: 'EDI', program: 'Viewer', url: '/edi/viewer/upload'
    add_program_function 'Recently sent', functional_area: 'EDI', program: 'Viewer', group: 'Sent', url: '/edi/viewer/sent/recently', seq: 2
    add_program_function 'Search sent by name', functional_area: 'EDI', program: 'Viewer', group: 'Sent', url: '/edi/viewer/sent/search_by_name', seq: 3
    add_program_function 'Search sent by content', functional_area: 'EDI', program: 'Viewer', group: 'Sent', url: '/edi/viewer/sent/search_by_content', seq: 4
    add_program_function 'Recently received', functional_area: 'EDI', program: 'Viewer', group: 'Received', url: '/edi/viewer/received/recently', seq: 5
    add_program_function 'Search received by name', functional_area: 'EDI', program: 'Viewer', group: 'Received', url: '/edi/viewer/received/search_by_name', seq: 6
    add_program_function 'Search received by content', functional_area: 'EDI', program: 'Viewer', group: 'Received', url: '/edi/viewer/received/search_by_content', seq: 7
  end

  down do
    drop_functional_area 'EDI'
  end
end
