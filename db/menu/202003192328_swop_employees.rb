Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Swop Employees', functional_area: 'Masterfiles', program: 'HR', url: '/masterfiles/human_resources/shift_types/swop_employees', seq: 9, group: 'Shift Types'
    add_program_function 'Move Employees', functional_area: 'Masterfiles', program: 'HR', url: '/masterfiles/human_resources/shift_types/move_employees', seq: 10, group: 'Shift Types'
  end

  down do
    drop_program_function 'Swop Employees', functional_area: 'Masterfiles', program: 'HR'
    drop_program_function 'Move Employees', functional_area: 'Masterfiles', program: 'HR'
  end
end
