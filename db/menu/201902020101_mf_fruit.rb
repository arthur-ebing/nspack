Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program 'Fruit', functional_area: 'Masterfiles'
    add_program_function 'Groups', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/commodity_groups', group: 'Commodities'
    add_program_function 'Commodities', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/commodities', seq: 2, group: 'Commodities'
    add_program_function 'Groups', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/cultivar_groups', seq: 3, group: 'Cultivars'
    add_program_function 'Cultivars', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/cultivars', seq: 4, group: 'Cultivars'
    add_program_function 'Marketing Varieties', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/marketing_varieties', seq: 5, group: 'Cultivars'
    add_program_function 'Std Fruit Size Counts', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/std_fruit_size_counts', seq: 6, group: 'Sizes'
    add_program_function 'Size References', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/fruit_size_references', seq: 7, group: 'Sizes'
    add_program_function 'Size Conversions', functional_area: 'Masterfiles', program: 'Fruit', url: '/search/fruit_actual_counts_for_packs', seq: 8, group: 'Sizes'
    add_program_function 'RMT Classes', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/rmt_classes', seq: 9
    add_program_function 'Grades', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/grades', seq: 10
    add_program_function 'Types', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/treatment_types', seq: 11, group: 'Treatments'
    add_program_function 'Treatments', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/treatments', seq: 12, group: 'Treatments'
    add_program_function 'Inventory Codes', functional_area: 'Masterfiles', program: 'Fruit', url: '/list/inventory_codes', seq: 12
  end

  down do
    drop_program 'Fruit', functional_area: 'Masterfiles'
  end
end
