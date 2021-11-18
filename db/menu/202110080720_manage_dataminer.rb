Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Manage', functional_area: 'Dataminer'

    move_program_function 'Report Admin', functional_area: 'Dataminer', program: 'Reports', to_program: 'Manage', to_functional_area: 'Dataminer'
    move_program_function 'Grid Admin', functional_area: 'Dataminer', program: 'Reports', to_program: 'Manage', to_functional_area: 'Dataminer'
    move_program_function 'Hide grid columns', functional_area: 'Dataminer', program: 'Reports', to_program: 'Manage', to_functional_area: 'Dataminer'

    change_program_function 'Report Admin', functional_area: 'Dataminer', program: 'Manage', seq: 1
    change_program_function 'Grid Admin', functional_area: 'Dataminer', program: 'Manage', seq: 2
    change_program_function 'Hide grid columns', functional_area: 'Dataminer', program: 'Manage', seq: 3

    change_program_function 'Prepared Reports', functional_area: 'Dataminer', program: 'Reports', seq: 2
    change_program_function 'ALL Prepared Reports', functional_area: 'Dataminer', program: 'Reports', seq: 3
  end

  down do
    move_program_function 'Report Admin', functional_area: 'Dataminer', program: 'Manage', to_program: 'Reports', to_functional_area: 'Dataminer'
    move_program_function 'Grid Admin', functional_area: 'Dataminer', program: 'Manage', to_program: 'Reports', to_functional_area: 'Dataminer'
    move_program_function 'Hide grid columns', functional_area: 'Dataminer', program: 'Manage', to_program: 'Reports', to_functional_area: 'Dataminer'

    change_program_function 'Report Admin', functional_area: 'Dataminer', program: 'Reports', seq: 2
    change_program_function 'Grid Admin', functional_area: 'Dataminer', program: 'Reports', seq: 3
    change_program_function 'Hide grid columns', functional_area: 'Dataminer', program: 'Reports', seq: 6

    change_program_function 'Prepared Reports', functional_area: 'Dataminer', program: 'Reports', seq: 4
    change_program_function 'ALL Prepared Reports', functional_area: 'Dataminer', program: 'Reports', seq: 5

    drop_program 'Manage', functional_area: 'Dataminer'
  end
end
