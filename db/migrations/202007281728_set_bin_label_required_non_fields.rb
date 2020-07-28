Sequel.migration do
  up do
    alter_table(:rmt_bin_labels) do
      set_column_allow_null :cultivar_id, true
      set_column_allow_null :farm_id, true
      set_column_allow_null :puc_id, true
      set_column_allow_null :orchard_id, true
    end
  end

  down do
    alter_table(:rmt_bin_labels) do
      set_column_allow_null :cultivar_id, false
      set_column_allow_null :farm_id, false
      set_column_allow_null :puc_id, false
      set_column_allow_null :orchard_id, false
    end
  end
end