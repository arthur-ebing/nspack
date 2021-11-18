Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Staged', functional_area: 'Lists', program: 'Bins', url: '/list/presort_bins/with_params?key=staged_presort_bins', group: 'Presort', seq: 8
    add_program_function 'Tipped', functional_area: 'Lists', program: 'Bins', url: '/list/presort_bins/with_params?key=tipped_presort_bins', group: 'Presort', seq: 9
    add_program_function 'Stock', functional_area: 'Lists', program: 'Bins', url: '/list/presort_bins/with_params?key=presort_bin_stock', group: 'Presort', seq: 10
    add_program_function 'Shipped', functional_area: 'Lists', program: 'Bins', url: '/list/presort_bins/with_params?key=shipped_presort_bins', group: 'Presort', seq: 11
  end

  down do
    drop_program_function 'Staged', functional_area: 'Lists', program: 'Bins', match_group: 'Presort'
    drop_program_function 'Tipped', functional_area: 'Lists', program: 'Bins', match_group: 'Presort'
    drop_program_function 'Stock', functional_area: 'Lists', program: 'Bins', match_group: 'Presort'
    drop_program_function 'Shipped', functional_area: 'Lists', program: 'Bins', match_group: 'Presort'
  end
end
