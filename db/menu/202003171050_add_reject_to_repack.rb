Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'New', functional_area: 'Finished Goods', program: 'Inspection', url: '/finished_goods/inspection/reject_to_repack/new', group: 'Reject to Repack', seq: 2
    add_program_function 'List', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/repacked_pallets', group: 'Reject to Repack', seq: 3
    add_program_function 'Search', functional_area: 'Finished Goods', program: 'Inspection', url: '/search/repacked_pallets', group: 'Reject to Repack', seq: 4
    add_program_function 'Failed and not repacked Pallets', functional_area: 'Finished Goods', program: 'Inspection', url: '/list/stock_pallets/with_params?key=failed_and_not_repacked', group: 'Reject to Repack', seq: 5

  end

  down do
    drop_program_function 'New', functional_area: 'Finished Goods', program: 'Inspection', match_group: 'Reject to Repack'
    drop_program_function 'List', functional_area: 'Finished Goods', program: 'Inspection', match_group: 'Reject to Repack'
    drop_program_function 'Search', functional_area: 'Finished Goods', program: 'Inspection', match_group: 'Reject to Repack'
    drop_program_function 'Failed and not repacked Pallets', functional_area: 'Finished Goods', program: 'Inspection', match_group: 'Reject to Repack'
  end
end
