Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Costs', functional_area: 'Masterfiles'
    add_program_function 'Cost Types', functional_area: 'Masterfiles', program: 'Costs', url: '/list/cost_types'
    add_program_function 'Costs', functional_area: 'Masterfiles', program: 'Costs', url: '/list/costs'
  end

  down do
    drop_program 'Costs', functional_area: 'Masterfiles'
  end
end
