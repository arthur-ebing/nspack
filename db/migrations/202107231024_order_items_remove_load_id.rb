Sequel.migration do
  up do
    alter_table(:order_items) do
      drop_foreign_key :load_id
    end
  end

  down do
    alter_table(:order_items) do
      add_foreign_key :load_id, :loads, type: :integer
    end

    run "UPDATE order_items
         SET load_id = (SELECT DISTINCT load_id
                        FROM pallets
                        JOIN pallet_sequences ON pallet_sequences.pallet_id = pallets.id
                        WHERE pallet_sequences.order_item_id = order_items.id)"
  end
end
