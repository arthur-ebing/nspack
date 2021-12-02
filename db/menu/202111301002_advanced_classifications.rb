Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Ripeness Codes', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/ripeness_codes', group: 'Advanced Classifications', seq: 4
    add_program_function 'Handling Regimes', functional_area: 'Masterfiles', program: 'Raw Materials', url: '/list/rmt_handling_regimes', group: 'Advanced Classifications', seq: 5
  end

  down do
    drop_program_function 'Ripeness Codes', functional_area: 'Masterfiles', program: 'Raw Materials', match_group: 'Advanced Classifications'
    drop_program_function 'Handling Regimes', functional_area: 'Masterfiles', program: 'Raw Materials', match_group: 'Advanced Classifications'
  end
end
