Sequel.migration do
  up do
    run 'alter table pallets
      add constraint pallets_load_id_fkey
      foreign key (load_id) references loads;'
  end

  down do
    run 'alter table pallets
      drop constraint pallets_load_id_fkey;'
  end
end




