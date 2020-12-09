Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Active Groups', functional_area: 'Production', program: 'Shifts', url: '/list/group_incentives/with_params?key=active', group: 'Incentive Groups', seq: 6
    add_program_function 'Search Groups', functional_area: 'Production', program: 'Shifts', url: '/search/group_incentives', group: 'Incentive Groups', seq: 6
    add_program_function 'Search by Contact Worker', functional_area: 'Production', program: 'Shifts', url: '/production/shifts/group_incentives/search_by_contract_worker', group: 'Incentive Groups', seq: 6
  end

  down do
    drop_program_function 'Active Groups', functional_area: 'Production', program: 'Shifts', match_group: 'Incentive Groups'
    drop_program_function 'Search Groups', functional_area: 'Production', program: 'Shifts', match_group: 'Incentive Groups'
    drop_program_function 'Search by Contact Worker', functional_area: 'Production', program: 'Shifts', match_group: 'Incentive Groups'
  end
end
