Crossbeams::MenuMigrations::Migrator.migration('Nspack') do
  up do
    add_program_function 'Packer Roles', functional_area: 'Masterfiles', program: 'HR', group: 'Contract Worker Config', url: '/list/contract_worker_packer_roles', seq: 5
  end

  down do
    drop_program_function 'Packer Roles', functional_area: 'Masterfiles', match_group: 'Contract Worker Config', program: 'HR'
  end
end
