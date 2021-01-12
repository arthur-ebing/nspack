Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      alter_table(Sequel[:kromco_legacy][:messcada_modules]) do
        set_column_allow_null :cluster_id
      end
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      alter_table(Sequel[:kromco_legacy][:messcada_modules]) do
        set_column_not_null :cluster_id
      end
    end
  end
end
