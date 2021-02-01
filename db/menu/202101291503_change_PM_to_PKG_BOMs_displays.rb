Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    change_program_function 'PM Types', rename: 'PKG Types', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 8
    change_program_function 'PM Subtypes', rename: 'PKG Subtypes', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 9
    change_program_function 'PM Products', rename: 'PKG Products', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 10
    change_program_function 'PM BOMs', rename: 'PKG BOMs', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 11
    change_program_function 'Search PM BOMs Products', rename: 'Search PKG BOMs Products', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 12
    change_program_function 'PM Marks', rename: 'PKG Marks', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 13
  end

  down do
    change_program_function 'PKG Types', rename: 'PM Types', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 8
    change_program_function 'PKG Subtypes', rename: 'PM Subtypes', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 9
    change_program_function 'PKG Products', rename: 'PM Products', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 10
    change_program_function 'PKG BOMs', rename: 'PM BOMs', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 11
    change_program_function 'Search PKG BOMs Products', rename: 'Search PM BOMs Products', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 12
    change_program_function 'PKG Marks', rename: 'PM Marks', group: 'Bill of Materials', functional_area: 'Masterfiles', program: 'Packaging', match_group: 'Bill of Materials', seq: 13
  end
end
