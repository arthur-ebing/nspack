Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Marketing', functional_area: 'Masterfiles'
    add_program_function 'Marks', functional_area: 'Masterfiles', program: 'Marketing', url: '/list/marks'
    add_program_function 'Customer Varieties', functional_area: 'Masterfiles', program: 'Marketing', url: '/list/customer_varieties', seq: 2
    add_program_function 'Search Customer Variety Marketing Varieties', functional_area: 'Masterfiles', program: 'Marketing', url: '/search/customer_variety_varieties', seq: 3
  end

  down do
    drop_program 'Marketing', functional_area: 'Masterfiles'
  end
end
