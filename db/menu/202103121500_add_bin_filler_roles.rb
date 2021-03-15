Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Bin Filler Roles', functional_area: 'Production', program: 'Runs', url: '/production/runs/bin_filler_roles/view_robots', seq: 8
  end

  down do
    drop_program_function 'Bin Filler Roles', functional_area: 'Production', program: 'Runs'
  end
end
