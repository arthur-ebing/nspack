Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Grower Grading', functional_area: 'Production'
    add_program_function 'Grading Rules', functional_area: 'Production', program: 'Grower Grading', url: '/list/grower_grading_rules', seq: 1
    add_program_function 'Grading Rule Items', functional_area: 'Production', program: 'Grower Grading', url: '/list/grower_grading_rule_items', seq: 2
    add_program_function 'Search Grading Rules', functional_area: 'Production', program: 'Grower Grading', url: '/search/grower_grading_rules', seq: 3
    add_program_function 'Grading Pools', functional_area: 'Production', program: 'Grower Grading', url: '/list/grower_grading_pools', seq: 4
    add_program_function 'Search Grading Pools', functional_area: 'Production', program: 'Grower Grading', url: '/search/grower_grading_pools', seq: 5
    add_program_function 'Cartons', functional_area: 'Production', program: 'Grower Grading', url: '/list/grower_grading_carton_details', group: 'List Objects', seq: 6
    add_program_function 'Rebins', functional_area: 'Production', program: 'Grower Grading', url: '/list/grower_grading_rebin_details', group: 'List Objects', seq: 7
    add_program_function 'Cartons', functional_area: 'Production', program: 'Grower Grading', url: '/search/grower_grading_cartons', group: 'Search Objects', seq: 8
    add_program_function 'Rebins', functional_area: 'Production', program: 'Grower Grading', url: '/search/grower_grading_rebins', group: 'Search Objects', seq: 9
  end

  down do
    drop_program 'Grower Grading', functional_area: 'Production'
  end
end
