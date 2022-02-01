Sequel.migration do
  up do
    alter_table(:colour_percentages) do
      add_index [:colour_percentage, :commodity_id], name: :colour_percentage_commodity_idx, unique: true
      drop_index [:description, :commodity_id], name: :color_percentage_unique_code
    end
  end

  down do
    alter_table(:colour_percentages) do
      drop_index :colour_percentage_commodity_idx
      add_index [:description, :commodity_id], name: :color_percentage_unique_code, unique: true
    end
  end
end