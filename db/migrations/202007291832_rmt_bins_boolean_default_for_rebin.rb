# require 'sequel_postgresql_triggers' # Uncomment this line for created_at and updated_at triggers.
Sequel.migration do
  up do
    alter_table(:rmt_bins) do
      set_column_default :is_rebin, false
    end

    run 'UPDATE rmt_bins SET is_rebin = false WHERE is_rebin IS NULL'
  end

  down do
    alter_table(:rmt_bins) do
      set_column_default :is_rebin, nil
    end

    run 'UPDATE rmt_bins SET is_rebin = NULL WHERE NOT is_rebin'
  end
end
