require 'sequel_postgresql_triggers'
Sequel.migration do
  up do
    extension :pg_triggers

    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not run (only applicable to Kromco)'
    else
      # Schema: kromco_legacy
      # -----------------------------------------------------
      run <<~SQL
        CREATE SCHEMA kromco_legacy;

        COMMENT ON SCHEMA kromco_legacy IS 'Legacy tables for use by Kromco MesScada java app';
      SQL

      # party_types
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:party_types], ignore_index_errors: true) do
        primary_key :id
        String :party_type_name, null: false
      end

      # SEEDS FOR party types
      run "INSERT INTO kromco_legacy.party_types(party_type_name, id) VALUES('PERSON', 1);"
      run "INSERT INTO kromco_legacy.party_types(party_type_name, id) VALUES('ORGANISATION', 2);"

      # parties
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:parties], ignore_index_errors: true) do
        primary_key :id
        foreign_key :party_type_id, Sequel[:kromco_legacy][:party_types], null: false
        String :party_name
        String :party_type_name

        index [:party_name], name: :kr_leg_parties_idx, unique: true
      end

      # people
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:people], ignore_index_errors: true) do
        primary_key :id
        foreign_key :party_id, Sequel[:kromco_legacy][:parties], null: false
        String :first_name
        String :last_name
        String :title
        Date :date_of_birth
        String :maiden_name
        String :industry_number
        String :initials
        TrueClass :is_deleted, default: false
        TrueClass :is_logged_on, default: false
        String :logged_onto_module
        Time :logged_onoff_time
        String :reader_id
        String :affected_by_env
        String :affected_by_function
        String :affected_by_program
        String :created_by
        String :updated_by
        String :default_role
        String :selected_role
        String :abbr_name
        TrueClass :from_external_system, default: false
        DateTime :created_at, null: false
        DateTime :updated_at, null: false

        index [:industry_number], name: :kr_leg_people_indus_unique_code, unique: true
      end

      pgt_created_at(Sequel[:kromco_legacy][:people],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_people_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:people],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_people_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_facilities
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_facilities], ignore_index_errors: true) do
        primary_key :id
        String :code, null: false, unique: true, unique_constraint_name: :unique_facility_code
        Integer :packhouse_number
        String :puc_phc
        String :gln
        TrueClass :is_active, default: true
        String :desc_short, null: false
        String :desc_medium
        String :desc_long
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_facilities],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_facilities_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_facilities],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_facilities_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_servers
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_servers], ignore_index_errors: true) do
        primary_key :id
        foreign_key :facility_id, Sequel[:kromco_legacy][:messcada_facilities], null: false
        String :code, null: false, unique: true, unique_constraint_name: :unique_server_code
        String :facility_code, null: false
        String :tcp_ip, null: false, default: '127.0.0.1'
        Integer :tcp_port , null: false, default: 2000
        String :web_ip , null: false, default: '127.0.0.1'
        Integer :web_port , null: false, default: 2080
        TrueClass :is_active, null: false, default: true
        String :desc_short, null: false
        String :desc_medium
        String :desc_long
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
        unique [:code, :facility_code]
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_servers],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_servers_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_servers],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_servers_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_clusters
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_clusters], ignore_index_errors: true) do
        primary_key :id
        foreign_key :server_id, Sequel[:kromco_legacy][:messcada_servers], null: false
        String :code, null: false, unique: true, unique_constraint_name: :unique_cluster_code
        String :server_code, null: false
        TrueClass :is_active, null: false, default: true
        String :desc_short, null: false
        String :desc_medium
        String :desc_long
        String :facility_code
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
        unique [:code, :server_code]
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_clusters],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_clusters_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_clusters],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_clusters_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_group_data
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_group_data], ignore_index_errors: true) do
        primary_key :id
        String :reader_id, null: false
        String :module_name, null: false
        String :group_id
        String :group_date
        TrueClass :from_external_system, default: false
        DateTime :created_at, null: false
        DateTime :updated_at, null: false

        index [:group_id], name: :kr_leg_messcada_group_data_idx
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_group_data],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_group_data_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_group_data],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_group_data_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_modules
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_modules], ignore_index_errors: true) do
        primary_key :id
        foreign_key :cluster_id, Sequel[:kromco_legacy][:messcada_clusters], null: false
        String :code, null: false, unique: true, unique_constraint_name: :unique_module_code
        String :cluster_code
        String :module_type_code, null: false
        String :module_function_type_code, null: false
        String :ip, null: false, default: '127.0.0.1'
        Integer :port, null: false, default: 2000
        TrueClass :is_active, null: false, default: true
        Integer :robot_printer_id
        String :robot_printer_code
        String :mac_address
        String :name
        String :parameters, default: '<Parameters Login="true" GlobalLoginControl="true" Encoding="UTF-8"   ButtonNameList="1,2"   />'
        TrueClass :button_multiples, default: true
        String :facility_code
        String :server_code
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
        unique [:code, :cluster_code]
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_modules],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_modules_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_modules],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_modules_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_people_roles
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_people_roles], ignore_index_errors: true) do
        primary_key :id
        String :code, null: false, unique: true, unique_constraint_name: :unique_people_roles_code
        String :description
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_people_roles],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_people_roles_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_people_roles],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_people_roles_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_people_group_members
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_people_group_members], ignore_index_errors: true) do
        primary_key :id
        String :reader_id
        String :rfid, null: false
        String :industry_number
        String :group_id
        String :group_date
        String :module_name
        String :module_name_alias
        String :last_name
        String :first_name
        String :initials
        String :title
        foreign_key :person_role, Sequel[:kromco_legacy][:messcada_people_roles], key: :code, type: String
        TrueClass :from_external_system, default: false
        DateTime :created_at, null: false
        DateTime :updated_at, null: false

        index [:reader_id, :group_id, :group_date, :industry_number], name: :kr_leg_messcada_people_group_members_idx, unique: true
        index [:group_id], name: :kr_leg_messcada_people_group_members_idx1
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_people_group_members],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_people_group_members_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_people_group_members],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_people_group_members_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_people_view_messcada_rfid_allocations
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_people_view_messcada_rfid_allocations], ignore_index_errors: true) do
        primary_key :id
        String :industry_number, null: false
        String :rfid, null: false, unique: true, unique_constraint_name: :messcada_people_view_messcada_rfid_allocations_rfid_key
        Integer :person_id
        DateTime :start_date
        DateTime :end_date
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_people_view_messcada_rfid_allocations],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_people_view_messcada_rfid_allocations_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_people_view_messcada_rfid_allocations],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_people_view_messcada_rfid_allocations_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_peripherals
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_peripherals], ignore_index_errors: true) do
        primary_key :id
        String :code, null: false, unique: true, unique_constraint_name: :unique_peripheral_code
        String :module_code
        String :peripheral_type_code, null: false
        TrueClass :is_active, null: false, default: true
        String :comms_type_code, null: false
        String :ip, null: false, default: '127.0.0.1'
        Integer :port, null: false, default: 9100
        Integer :baud, null: false, default: 19200
        String :parity, default: 'N'
        Integer :databooleans, null: false, default: 8
        Integer :stopboolean, null: false, default: 1
        String :flow_control, null: false, default: 'XONXOFF'
        String :start_of_input
        String :end_of_input
        TrueClass :messages, null: false, default: true
        TrueClass :button, null: false, default: true
        String :button_tooltip, null: false, default: 'Tooltip text'
        TrueClass :keyboard_robot, null: false, default: true
        Integer :input_buffer_length, null: false, default: 512
        Integer :output_buffer_length, null: false, default: 512
        Integer :timeout_milli_seconds, null: false, default: 0
        String :device_name, null: false, default: 'NetClient'
        String :mac_address
        String :parameters, null: false, default: '<Parameters Rules="False" />'
        String :communication_parameters, null: false, default: '<CommunicationParameters Rules="False" />'
        String :network_parameters, null: false, default: '<NetworkParameters Rules="False" />'
        String :dbms_parameters, null: false, default: '<DbmsParameters Rules="False" />'
        String :application_parameters, null: false, default: '<ApplicationParameters Rules="False" />'
        String :facility_code
        String :server_code
        String :cluster_code
        String :peripheral_group_code
        foreign_key :module_id, Sequel[:kromco_legacy][:messcada_modules]
        Integer :facility_id
        Integer :server_id
        Integer :cluster_id
        unique [:code, :module_code]
      end

      # messcada_peripheral_printers
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_peripheral_printers], ignore_index_errors: true) do
        primary_key :id
        String :peripheral_code, null: false
        String :internal_template_file
        String :internal_font_file
        String :label_template_file
        Integer :label_mode, null: false, default: 0
        Integer :gtin_mode, default: 0
        Integer :do_maximum_label, null: false, default: 1000
        TrueClass :apply_maximum_label_use, null: false, default: false
        Integer :render_amount, null: false, default: 1
        TrueClass :special_character_printer, default: true
        foreign_key :peripheral_id, Sequel[:kromco_legacy][:messcada_peripherals]
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_peripheral_printers],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_peripheral_printers_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_peripheral_printers],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_peripheral_printers_set_updated_at',
                     trigger_name: :set_updated_at)

      # messcada_rfid_allocations
      # -----------------------------------------------------
      create_table(Sequel[:kromco_legacy][:messcada_rfid_allocations], ignore_index_errors: true) do
        primary_key :id
        String :rfid, null: false, unique: true, unique_constraint_name: :messcada_rfid_allocations_rfid_key
        String :affected_by_env
        String :affected_by_function
        String :affected_by_program
        String :created_by
        String :updated_by
        DateTime :created_at, null: false
        DateTime :updated_at, null: false
      end

      pgt_created_at(Sequel[:kromco_legacy][:messcada_rfid_allocations],
                     :created_at,
                     function_name: 'kromco_legacy.pgt_messcada_rfid_allocations_set_created_at',
                     trigger_name: :set_created_at)

      pgt_updated_at(Sequel[:kromco_legacy][:messcada_rfid_allocations],
                     :updated_at,
                     function_name: 'kromco_legacy.pgt_messcada_rfid_allocations_set_updated_at',
                     trigger_name: :set_updated_at)
    end
  end

  down do
    if ENV['CLIENT_CODE'] != 'kr'
      puts 'Migration not rolled-back (only applicable to Kromco)'
    else
      drop_trigger(Sequel[:kromco_legacy][:messcada_rfid_allocations], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_rfid_allocations_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_rfid_allocations], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_rfid_allocations_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_rfid_allocations])

      drop_trigger(Sequel[:kromco_legacy][:messcada_peripheral_printers], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_peripheral_printers_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_peripheral_printers], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_peripheral_printers_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_peripheral_printers])

      drop_table(Sequel[:kromco_legacy][:messcada_peripherals])

      drop_trigger(Sequel[:kromco_legacy][:messcada_people_view_messcada_rfid_allocations], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_people_view_messcada_rfid_allocations_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_people_view_messcada_rfid_allocations], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_people_view_messcada_rfid_allocations_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_people_view_messcada_rfid_allocations])

      drop_trigger(Sequel[:kromco_legacy][:messcada_people_group_members], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_people_group_members_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_people_group_members], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_people_group_members_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_people_group_members])

      drop_trigger(Sequel[:kromco_legacy][:messcada_people_roles], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_people_roles_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_people_roles], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_people_roles_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_people_roles])

      drop_trigger(Sequel[:kromco_legacy][:messcada_modules], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_modules_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_modules], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_modules_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_modules])

      drop_trigger(Sequel[:kromco_legacy][:messcada_group_data], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_group_data_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_group_data], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_group_data_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_group_data])

      drop_trigger(Sequel[:kromco_legacy][:messcada_clusters], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_clusters_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_clusters], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_clusters_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_clusters])

      drop_trigger(Sequel[:kromco_legacy][:messcada_servers], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_servers_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_servers], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_servers_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_servers])

      drop_trigger(Sequel[:kromco_legacy][:messcada_facilities], :set_created_at)
      drop_function('kromco_legacy.pgt_messcada_facilities_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:messcada_facilities], :set_updated_at)
      drop_function('kromco_legacy.pgt_messcada_facilities_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:messcada_facilities])

      drop_trigger(Sequel[:kromco_legacy][:people], :set_created_at)
      drop_function('kromco_legacy.pgt_people_set_created_at')
      drop_trigger(Sequel[:kromco_legacy][:people], :set_updated_at)
      drop_function('kromco_legacy.pgt_people_set_updated_at')
      drop_table(Sequel[:kromco_legacy][:people])

      drop_table(Sequel[:kromco_legacy][:parties])
      drop_table(Sequel[:kromco_legacy][:party_types])
      run 'DROP SCHEMA kromco_legacy;'
    end
  end
end
