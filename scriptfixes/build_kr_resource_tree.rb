# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
require_relative '../app_loader'
# require_relative '../lib/base_repo'
# require_relative '../lib/applets/production_applet'

# What this script does:
# ----------------------
# Builds the resource tree for Kromco (plant and system)
#
# Reason for this script:
# -----------------------
# There are a lot of resources to be defined, so a re-runnable script can be used to get the design right.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb BuildKrResourceTree
# Live  : RACK_ENV=production ruby scripts/base_script.rb BuildKrResourceTree
# Dev   : ruby scripts/base_script.rb BuildKrResourceTree
#
class BuildKrResourceTree < BaseScript # rubocop:disable Metrics/ClassLength
  attr_reader :repo, :ph_id, :line_type, :reverse, :itpc_type, :drop_station, :drop_type, :printer_type, :clm_type, :btn_type,
              :ptz_type, :bay_type, :ship_type, :subline_type

  def run # rubocop:disable Metrics/PerceivedComplexity
    # Make this reversable using a parameter

    @reverse = args.length == 1

    @repo = ProductionApp::ResourceRepo.new
    @ph_id = @repo.get_id(:plant_resources, plant_resource_code: 'KROMCO_PACKHOUSE')
    return failed_response('KROMCO PACKHOUSE resource does not exist!') if @ph_id.nil?

    @line_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::LINE)
    @subline_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::SUB_LINE)
    @itpc_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::ITPC)
    @drop_station = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::DROP_STATION)
    @drop_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::DROP)
    @printer_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PRINTER)
    @clm_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::CLM_ROBOT)
    @btn_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::ROBOT_BUTTON)
    @ptz_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PALLETIZING_ROBOT)
    @bay_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PALLETIZING_BAY)
    @ship_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PALLETIZING_SHIP)

    if debug_mode
      puts "Updated something #{some_value}: #{some_change}"
    else
      DB.transaction do
        if reverse
          puts "\nDropping logoff ITPC"
          plant_id = repo.get_id(:plant_resources, plant_resource_code: 'DPK-40')
          repo.delete_plant_resource(plant_id)
          %w[41 42 43 44 45 46].each { |line| drop_dp_line(line) }
          drop_old_line(1)
          drop_old_line(2)
          drop_palletizers
        else
          # # Logoff ITPC - HAS TO BE ON A LINE.... - is this valid? or should we allow on PH?
          puts "\nBuilding logoff ITPC"
          res = plant_res(itpc_type, 'DPK-40', 'Logoff ITPC')
          itpc_id = repo.create_child_plant_resource(ph_id, res, sys_code: 'DPK-40')
          sysres_id = repo.get(:plant_resources, itpc_id, :system_resource_id)
          attrs = { ip_address: '172.16.35.200', port: 2000, group_incentive: true, login: true, logoff: true, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'server' }
          repo.update_system_resource(sysres_id, attrs)

          # Dedicated pack (Need packpoint robots)
          %w[41 42 43 44 45 46].each { |line| build_dp_line(line) }
          # Line 1, Line 2 (Need sub-line split and ITPC system details printer on the line?)
          build_old_line(1)
          build_old_line(2)
          build_palletizers
          # Rebin
          # Bin tip (ITPC & old lines)
        end
      end
    end

    if debug_mode
      success_response('Dry run complete')
    else
      puts 'DONE'
      success_response('Something was done')
    end
  end

  private

  def drop_dp_line(line_no)
    puts "\nDropping DP line #{line_no}..."
    4.times do |n|
      plant_id = repo.get_id(:plant_resources, plant_resource_code: "#{line_no}C2B#{n + 1}")
      repo.delete_plant_resource(plant_id)
    end
    clm_id = repo.get_id(:plant_resources, plant_resource_code: "DPK-#{line_no}-C2")
    repo.link_peripherals(clm_id, [])
    plant_id = repo.get_id(:plant_resources, plant_resource_code: "PRN-#{line_no}-C2")
    repo.delete_plant_resource(plant_id)
    repo.delete_plant_resource(clm_id)
    4.times do |n|
      plant_id = repo.get_id(:plant_resources, plant_resource_code: "DPK-#{line_no}-C2-PP#{n + 1}")
      repo.delete_plant_resource(plant_id)
    end
    plant_id = repo.get_id(:plant_resources, plant_resource_code: "DPK-#{line_no}-C2D")
    repo.delete_plant_resource(plant_id)

    plant_id = repo.get_id(:plant_resources, plant_resource_code: "#{line_no}DP#{line_no}")
    repo.delete_plant_resource(plant_id)
    plant_id = repo.get_id(:plant_resources, plant_resource_code: "DPK-#{line_no}")
    repo.delete_plant_resource(plant_id)
    plant_id = repo.get_id(:plant_resources, plant_resource_code: "DP-LINE-#{line_no}")
    repo.delete_plant_resource(plant_id)
  end

  def build_dp_line(line_no)
    dp_line_attrs = {
      '41' => { ip_address: '172.16.35.199', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'server' },
      '42' => { ip_address: '172.16.35.201', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'server' },
      '43' => { ip_address: '172.16.35.202', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'server' },
      '44' => { ip_address: '172.16.35.203', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'server' },
      '45' => { ip_address: '172.16.35.204', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'server' },
      '46' => { ip_address: '172.16.35.205', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'server' }
    }
    dp_clm_attrs = {
      '41' => { ip_address: '172.16.145.51', mac_address: '00:60:35:17:82:D4', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'robot-T200', robot_function: 'HTTP-CartonLabel', module_function: 'TERMINAL', ttl: 10_000, cycle_time: 9000, module_action: 'carton_labelling' },
      '42' => { ip_address: '172.16.145.52', mac_address: '00:60:35:17:82:DC', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'robot-T200', robot_function: 'HTTP-CartonLabel', module_function: 'TERMINAL', ttl: 10_000, cycle_time: 9000, module_action: 'carton_labelling' },
      '43' => { ip_address: '172.16.145.53', mac_address: '00:60:35:17:80:F4', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'robot-T200', robot_function: 'HTTP-CartonLabel', module_function: 'TERMINAL', ttl: 10_000, cycle_time: 9000, module_action: 'carton_labelling' },
      '44' => { ip_address: '172.16.145.54', mac_address: '00:60:35:17:82:D6', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'robot-T200', robot_function: 'HTTP-CartonLabel', module_function: 'TERMINAL', ttl: 10_000, cycle_time: 9000, module_action: 'carton_labelling' },
      '45' => { ip_address: '172.16.145.55', mac_address: '00:60:35:17:82:DB', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'robot-T200', robot_function: 'HTTP-CartonLabel', module_function: 'TERMINAL', ttl: 10_000, cycle_time: 9000, module_action: 'carton_labelling' },
      '46' => { ip_address: '172.16.145.56', mac_address: '00:60:35:29:A8:97', port: 2000, group_incentive: true, login: true, logoff: false, legacy_messcada: true, equipment_type: 'robot-T200', robot_function: 'HTTP-CartonLabel', module_function: 'TERMINAL', ttl: 10_000, cycle_time: 9000, module_action: 'carton_labelling' }
    }
    puts "\nBuilding DP line #{line_no}..."
    # resource_properties: GLN, PHC
    res = plant_res(line_type, "DP-LINE-#{line_no}", "Dedicated pack line #{line_no}")

    line_id = repo.create_child_plant_resource(ph_id, res)

    res = plant_res(itpc_type, "DPK-#{line_no}", "Dedicated pack ITPC #{line_no}")
    itpc_id = repo.create_child_plant_resource(line_id, res, sys_code: "DPK-#{line_no}")
    sysres_id = repo.get(:plant_resources, itpc_id, :system_resource_id)
    repo.update_system_resource(sysres_id, dp_line_attrs[line_no])

    # get sysres id from itpc_id & update with relevant attrs...
    res = plant_res(drop_station, "#{line_no}DP#{line_no}", "Dedicated pack packpoint #{line_no}")
    repo.create_child_plant_resource(line_id, res)
    res = plant_res(drop_type, "DPK-#{line_no}-C2D", "Class 2 drop #{line_no}")
    drop_id = repo.create_child_plant_resource(line_id, res)
    4.times do |n|
      res = plant_res(drop_station, "DPK-#{line_no}-C2-PP#{n + 1}", "Class 2 packpoint #{n + 1} for #{line_no}")
      repo.create_child_plant_resource(drop_id, res)
    end

    # create printer...
    res = plant_res(printer_type, "PRN-#{line_no}-C2", "Class 2 printer #{line_no}")
    printer_id = repo.create_child_plant_resource(line_id, res)
    # create clm with buttons
    res = plant_res(clm_type, "DPK-#{line_no}-C2", "Class 2 robot #{line_no}")
    clm_id = repo.create_child_plant_resource(line_id, res, sys_code: "DPK-#{line_no}-C2")
    sysres_id = repo.get(:plant_resources, clm_id, :system_resource_id)
    repo.update_system_resource(sysres_id, dp_clm_attrs[line_no])
    # Add buttons (& link to packpoints...)
    4.times do |n|
      res = plant_res(btn_type, "#{line_no}C2B#{n + 1}", "Class 2 robot #{line_no} Button B#{n + 1}")
      repo.create_child_plant_resource(clm_id, res, sys_code: "#{line_no}C2B#{n + 1}")
    end
    # link printer
    sysres_id = repo.get(:plant_resources, printer_id, :system_resource_id)
    repo.link_a_peripheral(clm_id, sysres_id)

    # For each line:
    # create line
    # ---- itpc printer
    # itpc & link prn (with sysres data)
    # dp packpoint
    #
    # cl 2 packpoints
    # cl 2 printer
    # class 2 clm & link prn (with sysres data)
    # clm buttons pointing to ppoint
  end

  def drop_old_line(line_no)
    puts "\nDropping line #{line_no}"
    # get line and delete all drops and drop stations
    40.times do |drop_no| # Need to mix in qty for sub-line...
      2.times do |stn_no|
        plant_id = repo.get_id(:plant_resources, plant_resource_code: "PP-#{line_no}-#{drop_no + 1}-#{stn_no + 1}")
        repo.delete_plant_resource(plant_id)
      end

      plant_id = repo.get_id(:plant_resources, plant_resource_code: "DROP-#{line_no}-#{drop_no + 1}")
      repo.delete_plant_resource(plant_id)
    end
    plant_id = repo.get_id(:plant_resources, plant_resource_code: "LBL-#{line_no}A")
    repo.delete_plant_resource(plant_id)
    plant_id = repo.get_id(:plant_resources, plant_resource_code: "SUB-LINE-#{line_no}")
    repo.delete_plant_resource(plant_id)
    plant_id = repo.get_id(:plant_resources, plant_resource_code: "LINE-#{line_no}")
    repo.delete_plant_resource(plant_id)
  end

  def build_old_line(line_no)
    itpc_attrs = {
      1 => { ip_address: '172.16.35.104', port: 2000, group_incentive: false, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'demand', ttl: 10_000, cycle_time: 9000, module_action: 'server' },
      2 => { ip_address: '172.16.35.65', port: 2000, group_incentive: false, login: true, logoff: false, legacy_messcada: true, equipment_type: 'ITPC', robot_function: 'HTTP-CartonLabel', module_function: 'demand', ttl: 10_000, cycle_time: 9000, module_action: 'server' }
    }
    puts "\nBuilding line #{line_no}"
    res = plant_res(line_type, "LINE-#{line_no}", "Label line #{line_no}")

    line_id = repo.create_child_plant_resource(ph_id, res)

    res = plant_res(subline_type, "SUB-LINE-#{line_no}", "Sub line #{line_no}")
    repo.create_child_plant_resource(line_id, res)

    # ITPC
    res = plant_res(itpc_type, "LBL-#{line_no}A", "Line scanner LBL-#{line_no}A")
    itpc_id = repo.create_child_plant_resource(line_id, res, sys_code: "LBL-#{line_no}A")
    sysres_id = repo.get(:plant_resources, itpc_id, :system_resource_id)
    repo.update_system_resource(sysres_id, itpc_attrs[line_no])

    40.times do |drop_no| # Need to mix in qty for sub-line...
      res = plant_res(drop_type, "DROP-#{line_no}-#{drop_no + 1}", "Drop #{line_no}-#{drop_no + 1}")
      drop_id = repo.create_child_plant_resource(line_id, res)
      2.times do |stn_no|
        res = plant_res(drop_station, "PP-#{line_no}-#{drop_no + 1}-#{stn_no + 1}", "Drop packpoint #{line_no}-#{drop_no + 1}-#{stn_no + 1}")
        repo.create_child_plant_resource(drop_id, res)
      end
    end
  end

  def drop_palletizers
    puts "\nDropping palletizers..."
    # find all bays for the line & delete
    # find all ptz robots for the line & delete
    plant_ids = DB[:plant_resources]
                .join(:tree_plant_resources, descendant_plant_resource_id: Sequel[:plant_resources][:id])
                .join(:plant_resource_types, id: Sequel[:plant_resources][:plant_resource_type_id])
                .where(Sequel[:tree_plant_resources][:ancestor_plant_resource_id] => ph_id)
                .where(Sequel[:plant_resource_types][:plant_resource_type_code] => Crossbeams::Config::ResourceDefinitions::PALLETIZING_BAY)
                .select_map(Sequel[:plant_resources][:id])
    plant_ids.each { |plant_id| repo.delete_plant_resource(plant_id) }

    plant_ids = DB[:plant_resources]
                .join(:tree_plant_resources, descendant_plant_resource_id: Sequel[:plant_resources][:id])
                .join(:plant_resource_types, id: Sequel[:plant_resources][:plant_resource_type_id])
                .where(Sequel[:tree_plant_resources][:ancestor_plant_resource_id] => ph_id)
                .where(Sequel[:plant_resource_types][:plant_resource_type_code] => Crossbeams::Config::ResourceDefinitions::PALLETIZING_ROBOT)
                .select_map(Sequel[:plant_resources][:id])
    plant_ids.each { |plant_id| repo.delete_plant_resource(plant_id) }

    plant_ids = DB[:plant_resources]
                .join(:tree_plant_resources, descendant_plant_resource_id: Sequel[:plant_resources][:id])
                .join(:plant_resource_types, id: Sequel[:plant_resources][:plant_resource_type_id])
                .where(Sequel[:tree_plant_resources][:ancestor_plant_resource_id] => ph_id)
                .where(Sequel[:plant_resource_types][:plant_resource_type_code] => Crossbeams::Config::ResourceDefinitions::PALLETIZING_SHIP)
                .select_map(Sequel[:plant_resources][:id])
    plant_ids.each { |plant_id| repo.delete_plant_resource(plant_id) }
  end

  def build_palletizers
    puts "\nBuilding palletizers..."
    # SHIPS - for bays 1-10, Name SHIP 1A & SHIP 1B...
    ptz = {
      ship_1a: [
        { ip_address: '172.17.16.31', plant_resource_code: 'S1A-Bay-01', system_resource_code: 'PTM-01', old: 'PAL-L1A-01', mac_address: '00:60:35:16:D6:4D' },
        { ip_address: '172.17.16.32', plant_resource_code: 'S1A-Bay-02', system_resource_code: 'PTM-02', old: 'PAL-L1A-02', mac_address: '00:60:35:24:42:99' },
        { ip_address: '172.17.16.33', plant_resource_code: 'S1A-Bay-03', system_resource_code: 'PTM-03', old: 'PAL-L1A-03-L', mac_address: '00:60:35:24:42:98' },
        # { ip_address: '172.17.16.43', plant_resource_code: 'Bay-03', system_resource_code: 'PTM-04', old: 'PAL-L1A-03-R', mac_address: '00:60:35:29:A8:5F' },
        { ip_address: '172.17.16.34', plant_resource_code: 'S1A-Bay-04', system_resource_code: 'PTM-04', old: 'PAL-L1A-04', mac_address: '00:60:35:24:42:96' },
        { ip_address: '172.17.16.35', plant_resource_code: 'S1A-Bay-05', system_resource_code: 'PTM-05', old: 'PAL-L1A-05', mac_address: '00:60:35:24:A4:8F' },
        { ip_address: '172.17.16.36', plant_resource_code: 'S1A-Bay-06', system_resource_code: 'PTM-06', old: 'PAL-L1A-06', mac_address: '00:60:35:1F:A6:C1' },
        { ip_address: '172.17.16.37', plant_resource_code: 'S1A-Bay-07', system_resource_code: 'PTM-07', old: 'PAL-L1A-07', mac_address: '00:60:35:24:42:93' },
        { ip_address: '172.17.16.38', plant_resource_code: 'S1A-Bay-08', system_resource_code: 'PTM-08', old: 'PAL-L1A-08', mac_address: '00:60:35:24:42:9E' },
        { ip_address: '172.17.16.39', plant_resource_code: 'S1A-Bay-09', system_resource_code: 'PTM-09', old: 'PAL-L1A-09', mac_address: '00:60:35:24:42:92' },
        { ip_address: '172.17.16.40', plant_resource_code: 'S1A-Bay-10', system_resource_code: 'PTM-10', old: 'PAL-L1A-10', mac_address: '00:60:35:24:A4:90' }
      ],
      ship_1b: [
        { ip_address: '172.17.16.41', plant_resource_code: 'S1B-Bay-01', system_resource_code: 'PTM-11', old: 'PAL-L1B-01', mac_address: '00:60:35:24:42:A3' },
        { ip_address: '172.17.16.42', plant_resource_code: 'S1B-Bay-02', system_resource_code: 'PTM-12', old: 'PAL-L1B-02', mac_address: '00:60:35:1F:A6:C8' },
        { ip_address: '172.17.16.43', plant_resource_code: 'S1B-Bay-03', system_resource_code: 'PTM-13', old: 'PAL-L1B-03', mac_address: '00:60:35:1F:BB:15' },
        { ip_address: '172.17.16.44', plant_resource_code: 'S1B-Bay-04', system_resource_code: 'PTM-14', old: 'PAL-L1B-04', mac_address: '00:60:35:29:A8:4B' },
        { ip_address: '172.17.16.45', plant_resource_code: 'S1B-Bay-05', system_resource_code: 'PTM-15', old: 'PAL-L1B-05', mac_address: '00:60:35:29:A8:6F' },
        { ip_address: '172.17.16.46', plant_resource_code: 'S1B-Bay-06', system_resource_code: 'PTM-16', old: 'PAL-L1B-06', mac_address: '00:60:35:29:A8:5E' },
        { ip_address: '172.17.16.47', plant_resource_code: 'S1B-Bay-07', system_resource_code: 'PTM-17', old: 'PAL-L1B-07', mac_address: '00:60:35:29:A8:4D' },
        { ip_address: '172.17.16.48', plant_resource_code: 'S1B-Bay-08', system_resource_code: 'PTM-18', old: 'PAL-L1B-08', mac_address: '00:60:35:29:A8:77' },
        { ip_address: '172.17.16.49', plant_resource_code: 'S1B-Bay-09', system_resource_code: 'PTM-19', old: 'PAL-L1B-09', mac_address: '00:60:35:29:A8:61' },
        { ip_address: '172.17.16.50', plant_resource_code: 'S1B-Bay-10', system_resource_code: 'PTM-20', old: 'PAL-L1B-10', mac_address: '00:60:35:29:A8:60' }
      ],
      ship_2a: [
        { ip_address: '172.17.16.71', plant_resource_code: 'S2A-Bay-01', system_resource_code: 'PTM-21', old: 'PAL-L2A-01', mac_address: '00:60:35:29:A8:65' },
        { ip_address: '172.17.16.72', plant_resource_code: 'S2A-Bay-02', system_resource_code: 'PTM-22', old: 'PAL-L2A-02', mac_address: '00:60:35:29:A8:58' },
        { ip_address: '172.17.16.73', plant_resource_code: 'S2A-Bay-03', system_resource_code: 'PTM-23', old: 'PAL-L2A-03', mac_address: '00:60:35:29:A8:64' },
        { ip_address: '172.17.16.74', plant_resource_code: 'S2A-Bay-04', system_resource_code: 'PTM-24', old: 'PAL-L2A-04', mac_address: '00:60:35:29:A8:7A' },
        { ip_address: '172.17.16.75', plant_resource_code: 'S2A-Bay-05', system_resource_code: 'PTM-25', old: 'PAL-L2A-05', mac_address: '00:60:35:29:A8:4F' },
        { ip_address: '172.17.16.76', plant_resource_code: 'S2A-Bay-06', system_resource_code: 'PTM-26', old: 'PAL-L2A-06', mac_address: '00:60:35:29:A8:69' },
        { ip_address: '172.17.16.77', plant_resource_code: 'S2A-Bay-07', system_resource_code: 'PTM-27', old: 'PAL-L2A-07', mac_address: '00:60:35:29:A8:56' },
        { ip_address: '172.17.16.78', plant_resource_code: 'S2A-Bay-08', system_resource_code: 'PTM-28', old: 'PAL-L2A-08', mac_address: '00:60:35:24:42:A0' },
        { ip_address: '172.17.16.79', plant_resource_code: 'S2A-Bay-09', system_resource_code: 'PTM-29', old: 'PAL-L2A-09', mac_address: '00:60:35:29:A8:6D' },
        { ip_address: '172.17.16.80', plant_resource_code: 'S2A-Bay-10', system_resource_code: 'PTM-30', old: 'PAL-L2A-10', mac_address: '00:60:35:29:A8:4C' }
      ],
      ship_2b: [
        { ip_address: '172.17.16.81', plant_resource_code: 'S2B-Bay-01', system_resource_code: 'PTM-31', old: 'PAL-L2B-01', mac_address: '00:60:35:29:A8:57' },
        { ip_address: '172.17.16.82', plant_resource_code: 'S2B-Bay-02', system_resource_code: 'PTM-32', old: 'PAL-L2B-02', mac_address: '00:60:35:29:A8:62' },
        { ip_address: '172.17.16.83', plant_resource_code: 'S2B-Bay-03', system_resource_code: 'PTM-33', old: 'PAL-L2B-03', mac_address: '00:60:35:29:A8:5A' },
        { ip_address: '172.17.16.84', plant_resource_code: 'S2B-Bay-04', system_resource_code: 'PTM-34', old: 'PAL-L2B-04', mac_address: '00:60:35:29:A8:51' },
        { ip_address: '172.17.16.85', plant_resource_code: 'S2B-Bay-05', system_resource_code: 'PTM-35', old: 'PAL-L2B-05', mac_address: '00:60:35:29:A8:50' },
        { ip_address: '172.17.16.86', plant_resource_code: 'S2B-Bay-06', system_resource_code: 'PTM-36', old: 'PAL-L2B-06', mac_address: '00:60:35:29:A8:5C' },
        { ip_address: '172.17.16.87', plant_resource_code: 'S2B-Bay-07', system_resource_code: 'PTM-37', old: 'PAL-L2B-07', mac_address: '00:60:35:29:A8:5B' },
        { ip_address: '172.17.16.88', plant_resource_code: 'S2B-Bay-08', system_resource_code: 'PTM-38', old: 'PAL-L2B-08', mac_address: '00:60:35:29:A8:7C' },
        { ip_address: '172.17.16.89', plant_resource_code: 'S2B-Bay-09', system_resource_code: 'PTM-39', old: 'PAL-L2B-09', mac_address: '00:60:35:29:A8:6E' },
        { ip_address: '172.17.16.90', plant_resource_code: 'S2B-Bay-10', system_resource_code: 'PTM-40', old: 'PAL-L2B-10', mac_address: '00:60:35:29:A8:66' }
      ],
      ship_3a: [
        { ip_address: '172.17.16.51', plant_resource_code: 'S3A-Bay-01', system_resource_code: 'PTM-41', old: 'PAL-L3A-01', mac_address: '00:60:35:29:A8:79' },
        { ip_address: '172.17.16.52', plant_resource_code: 'S3A-Bay-02', system_resource_code: 'PTM-42', old: 'PAL-L3A-02', mac_address: '00:60:35:29:A8:78' },
        { ip_address: '172.17.16.53', plant_resource_code: 'S3A-Bay-03', system_resource_code: 'PTM-43', old: 'PAL-L3A-03', mac_address: '00:60:35:29:A8:6C' },
        { ip_address: '172.17.16.54', plant_resource_code: 'S3A-Bay-04', system_resource_code: 'PTM-44', old: 'PAL-L3A-04', mac_address: '00:60:35:29:A8:55' },
        { ip_address: '172.17.16.55', plant_resource_code: 'S3A-Bay-05', system_resource_code: 'PTM-45', old: 'PAL-L3A-05', mac_address: '00:60:35:29:A8:71' },
        { ip_address: '172.17.16.56', plant_resource_code: 'S3A-Bay-06', system_resource_code: 'PTM-46', old: 'PAL-L3A-06', mac_address: '00:60:35:29:A8:59' },
        { ip_address: '172.17.16.57', plant_resource_code: 'S3A-Bay-07', system_resource_code: 'PTM-47', old: 'PAL-L3A-07', mac_address: '00:60:35:29:A8:5D' },
        { ip_address: '172.17.16.58', plant_resource_code: 'S3A-Bay-08', system_resource_code: 'PTM-48', old: 'PAL-L3A-08', mac_address: '00:60:35:29:A8:72' },
        { ip_address: '172.17.16.59', plant_resource_code: 'S3A-Bay-09', system_resource_code: 'PTM-49', old: 'PAL-L3A-09', mac_address: '00:60:35:29:A8:53' },
        { ip_address: '172.17.16.60', plant_resource_code: 'S3A-Bay-10', system_resource_code: 'PTM-50', old: 'PAL-L3A-10', mac_address: '00:60:35:29:A8:54' }
      ],
      ship_3b: [
        { ip_address: '172.17.16.61', plant_resource_code: 'S3B-Bay-01', system_resource_code: 'PTM-51', old: 'PAL-L3B-01', mac_address: '00:60:35:29:A8:6B' },
        { ip_address: '172.17.16.62', plant_resource_code: 'S3B-Bay-02', system_resource_code: 'PTM-52', old: 'PAL-L3B-02', mac_address: '00:60:35:29:A8:76' },
        { ip_address: '172.17.16.63', plant_resource_code: 'S3B-Bay-03', system_resource_code: 'PTM-53', old: 'PAL-L3B-03', mac_address: '00:60:35:29:A8:74' },
        { ip_address: '172.17.16.64', plant_resource_code: 'S3B-Bay-04', system_resource_code: 'PTM-54', old: 'PAL-L3B-04', mac_address: '00:60:35:29:A8:7D' },
        { ip_address: '172.17.16.65', plant_resource_code: 'S3B-Bay-05', system_resource_code: 'PTM-55', old: 'PAL-L3B-05', mac_address: '00:60:35:29:A8:4E' },
        { ip_address: '172.17.16.66', plant_resource_code: 'S3B-Bay-06', system_resource_code: 'PTM-56', old: 'PAL-L3B-06', mac_address: '00:60:35:29:A8:73' },
        { ip_address: '172.17.16.67', plant_resource_code: 'S3B-Bay-07', system_resource_code: 'PTM-57', old: 'PAL-L3B-07', mac_address: '00:60:35:29:A8:7B' },
        { ip_address: '172.17.16.68', plant_resource_code: 'S3B-Bay-08', system_resource_code: 'PTM-58', old: 'PAL-L3B-08', mac_address: '00:60:35:29:A8:4A' },
        { ip_address: '172.17.16.69', plant_resource_code: 'S3B-Bay-09', system_resource_code: 'PTM-59', old: 'PAL-L3B-09', mac_address: '00:60:35:29:A8:52' },
        { ip_address: '172.17.16.70', plant_resource_code: 'S3B-Bay-10', system_resource_code: 'PTM-60', old: 'PAL-L3B-10', mac_address: '00:60:35:29:A8:63' }
      ],
      ship_4a: [
        { ip_address: '172.17.16.11', plant_resource_code: 'S4A-Bay-01', system_resource_code: 'PTM-61', old: 'PAL-L4-41-L', mac_address: '00:60:35:16:D6:4E' },
        { ip_address: '172.17.16.12', plant_resource_code: 'S4A-Bay-02', system_resource_code: 'PTM-62', old: 'PAL-L4-41-R', mac_address: '00:60:35:24:A4:89' },
        { ip_address: '172.17.16.13', plant_resource_code: 'S4A-Bay-03', system_resource_code: 'PTM-63', old: 'PAL-L4-42-L', mac_address: '00:60:35:16:D6:55' },
        { ip_address: '172.17.16.14', plant_resource_code: 'S4A-Bay-04', system_resource_code: 'PTM-64', old: 'PAL-L4-42-R', mac_address: '00:60:35:16:D6:4F' },
        { ip_address: '172.17.16.15', plant_resource_code: 'S4A-Bay-05', system_resource_code: 'PTM-65', old: 'PAL-L4-43-L', mac_address: '00:60:35:24:A4:8B' },
        { ip_address: '172.17.16.16', plant_resource_code: 'S4A-Bay-06', system_resource_code: 'PTM-66', old: 'PAL-L4-43-R', mac_address: '00:60:35:16:D6:4C' },
        { ip_address: '172.17.16.17', plant_resource_code: 'S4A-Bay-07', system_resource_code: 'PTM-67', old: 'PAL-L4-44-L', mac_address: '00:60:35:24:A4:8C' },
        { ip_address: '172.17.16.18', plant_resource_code: 'S4A-Bay-08', system_resource_code: 'PTM-68', old: 'PAL-L4-44-R', mac_address: '00:60:35:24:A4:8A' },
        { ip_address: '172.17.16.19', plant_resource_code: 'S4A-Bay-09', system_resource_code: 'PTM-69', old: 'PAL-L4-45-L', mac_address: '00:60:35:16:D6:57' },
        { ip_address: '172.17.16.20', plant_resource_code: 'S4A-Bay-10', system_resource_code: 'PTM-70', old: 'PAL-L4-45-R', mac_address: '00:60:35:16:D6:54' }
      ],
      ship_4b: [
        { ip_address: '172.17.16.21', plant_resource_code: 'S4B-Bay-01', system_resource_code: 'PTM-71', old: 'PAL-L4K2-01', mac_address: '00:60:35:16:D6:50' },
        { ip_address: '172.17.16.22', plant_resource_code: 'S4B-Bay-02', system_resource_code: 'PTM-72', old: 'PAL-L4K2-02', mac_address: '00:60:35:16:D6:4A' },
        { ip_address: '172.17.16.23', plant_resource_code: 'S4B-Bay-03', system_resource_code: 'PTM-73', old: 'PAL-L4K2-03', mac_address: '00:60:35:16:D6:53' },
        { ip_address: '172.16.34.24', plant_resource_code: 'S4B-Bay-04', system_resource_code: 'PTM-74', old: 'PAL-L4K2-04', mac_address: '00:60:35:16:D6:56' },
        { ip_address: '172.17.16.25', plant_resource_code: 'S4B-Bay-05', system_resource_code: 'PTM-75', old: 'PAL-L4K2-05', mac_address: '00:60:35:24:A4:88' },
        { ip_address: '172.17.16.26', plant_resource_code: 'S4B-Bay-06', system_resource_code: 'PTM-76', old: 'PAL-L4K2-06', mac_address: '00:60:35:16:D6:58' },
        { ip_address: '172.17.16.27', plant_resource_code: 'S4B-Bay-07', system_resource_code: 'PTM-77', old: 'PAL-L4K2-07', mac_address: '00:60:35:16:D6:4B' },
        { ip_address: '172.17.16.28', plant_resource_code: 'S4B-Bay-08', system_resource_code: 'PTM-78', old: 'PAL-L4K2-08', mac_address: '00:60:35:24:A4:87' },
        { ip_address: '172.17.16.29', plant_resource_code: 'S4B-Bay-09', system_resource_code: 'PTM-79', old: 'PAL-L4K2-09', mac_address: '00:60:35:16:D6:49' },
        { ip_address: '172.17.16.30', plant_resource_code: 'S4B-Bay-10', system_resource_code: 'PTM-80', old: 'PAL-L4K2-10', mac_address: '00:60:35:1F:A6:D8' }
      ],
      ship_5a: [
        { ip_address: '172.17.16.91', plant_resource_code: 'S5A-Bay-01', system_resource_code: 'PTM-81', old: 'PAL-SP-01', mac_address: '00:60:35:29:A8:70' },
        { ip_address: '172.17.16.92', plant_resource_code: 'S5A-Bay-02', system_resource_code: 'PTM-82', old: 'PAL-SP-02', mac_address: '00:60:35:29:A8:6A' },
        { ip_address: '172.17.16.93', plant_resource_code: 'S5A-Bay-03', system_resource_code: 'PTM-83', old: 'PAL-SP-03', mac_address: '00:60:35:24:42:97' },
        { ip_address: '172.17.16.94', plant_resource_code: 'S5A-Bay-04', system_resource_code: 'PTM-84', old: 'PAL-SP-04', mac_address: '00:60:35:29:A8:67' },
        { ip_address: '172.17.16.95', plant_resource_code: 'S5A-Bay-05', system_resource_code: 'PTM-85', old: 'PAL-SP-05', mac_address: '00:60:35:29:A8:75' },
        { ip_address: '172.16.34.96', plant_resource_code: 'S5A-Bay-06', system_resource_code: 'PTM-86', old: 'PAL-SP-06', mac_address: '00:60:35:24:42:9B' },
        { ip_address: '172.16.34.97', plant_resource_code: 'S5A-Bay-07', system_resource_code: 'PTM-87', old: 'PAL-SP-07', mac_address: '00:60:35:1F:A6:C9' }
      ]
    }

    ptz.each do |ship, bays|
      res = plant_res(ship_type, ship.to_s.upcase, "Palletizing #{ship.to_s.gsub('_', ' ').reverse.capitalize.reverse}")
      ship_id = repo.create_child_plant_resource(ph_id, res)

      bays.each do |node|
        # add palletizer + bay & set sysres values.
        res = plant_res(ptz_type, "#{node[:plant_resource_code]} ROBOT", "#{node[:plant_resource_code]} Robot")
        robot_id = repo.create_child_plant_resource(ship_id, res, sys_code: node[:system_resource_code])

        # if Bayn-1 or Bayn-2, create 2 bays with scanner code 1 & 2 (plant may already exist... (change hash to include l & r entries)
        res = plant_res(bay_type, node[:plant_resource_code], node[:plant_resource_code])
        bay_id = repo.create_child_plant_resource(robot_id, res)

        repo.create(:palletizing_bay_states,
                    palletizing_robot_code: node[:system_resource_code],
                    scanner_code: 1,
                    palletizing_bay_resource_id: bay_id,
                    current_state: 'empty')

        # Robot attributes
        attrs = { ip_address: node[:ip_address], port: 2000, equipment_type: 'robot-T200', robot_function: 'HTTP-PalletBuildup', module_function: 'pallet-buildup', ttl: 10_000, cycle_time: 9000, module_action: 'carton_palletizing', mac_address: node[:mac_address] }
        sysres_id = repo.get(:plant_resources, robot_id, :system_resource_id)
        repo.update_system_resource(sysres_id, attrs)
      end
    end
  end

  def plant_res(type, code, desc)
    ProductionApp::PlantResourceSchema.call(plant_resource_type_id: type, plant_resource_code: code, description: desc)
  end
end
# rubocop:enable Metrics/AbcSize
