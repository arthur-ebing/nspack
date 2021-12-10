Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Ripeness Codes', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/ripeness_codes', group: 'Advanced Classifications', seq: 4
    add_program_function 'Handling Regimes', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/rmt_handling_regimes', group: 'Advanced Classifications', seq: 5
    add_program_function 'Rmt Codes', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/rmt_codes', group: 'Advanced Classifications', seq: 6
    add_program_function 'Rmt Classifications', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/rmt_classifications', group: 'Advanced Classifications', seq: 7
  end

  down do
    drop_program_function 'Ripeness Codes', functional_area: 'Masterfiles', program: 'Raw Materials', match_group: 'Advanced Classifications'
    drop_program_function 'Handling Regimes', functional_area: 'Masterfiles', program: 'Raw Materials', match_group: 'Advanced Classifications'
    drop_program_function 'Rmt Codes', functional_area: 'Masterfiles', program: 'Raw Materials', match_group: 'Advanced Classifications'
    drop_program_function 'Rmt Classifications', functional_area: 'Masterfiles', program: 'Raw Materials', match_group: 'Advanced Classifications'
  end
end
