Sequel.migration do
  up do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      alter_table(:group_incentives) do
        add_column :from_external_system, :boolean, default: false
      end
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      alter_table(:group_incentives) do
        drop_column :from_external_system
      end
    end
  end
end
