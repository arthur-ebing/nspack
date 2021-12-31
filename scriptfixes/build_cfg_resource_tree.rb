# frozen_string_literal: true

require_relative '../app_loader'

# What this script does:
# ----------------------
# Updates system resource attributes from MesServer config files.
#
# Reason for this script:
# -----------------------
# The resource model was much less detailed when UD was set up initially.
# This script brings the attributes up to date.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb BuildUdResourceTree
# Live  : RACK_ENV=production ruby scripts/base_script.rb BuildUdResourceTree
# Dev   : ruby scripts/base_script.rb BuildUdResourceTree
#
class BuildCfgResourceTree < BaseScript
  attr_reader :repo, :ph_id, :line_type, :reverse, :line_id, :pack_point, :drop_type, :printer_type, :clm_type, :btn_type,
              :ptz_type, :bay_type, :ship_type, :subline_type, :bts_type, :btm_type

  # Spec: 130 NTD and 130 printers (network/usb, not decided yet)
  # ip range: 192.168.13.xxx, starting at .11
  # Server ip? No of buttons? (6?)
  # SITE
  #   MES
  #   PH3 (?)
  #     LINE 1
  #     LINE 2
  def run # rubocop:disable Metrics/AbcSize
    # Make this reversable using a parameter

    @reverse = args.length == 1

    @repo = ProductionApp::ResourceRepo.new
    @ph_id = @repo.get_id(:plant_resources, plant_resource_code: 'PH3')
    return failed_response('PH3 PACKHOUSE resource does not exist!') if @ph_id.nil?

    @line_id = @repo.get_id(:plant_resources, plant_resource_code: 'LINE3')
    return failed_response('LINE3 LINE resource does not exist!') if @line_id.nil?

    @line_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::LINE)
    @drop_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::DROP)
    @printer_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::PRINTER)
    @clm_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::CLM_ROBOT)
    @btn_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::ROBOT_BUTTON)
    @bts_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::BIN_TIPPING_STATION)
    @btm_type = @repo.plant_resource_type_id_from_code(Crossbeams::Config::ResourceDefinitions::BIN_TIPPING_ROBOT)

    DB.transaction do
      if reverse
        drop_modules_and_printers
      else
        create_modules_and_printers
      end
    end

    if debug_mode
      success_response('Dry run - nothing to do')
    else
      success_response('Attributes updated')
    end
  end

  private

  def drop_modules_and_printers # rubocop:disable Metrics/AbcSize
    130.times do |n|
      seq = n + 1
      seq_str = seq.to_s.rjust(3, '0')
      4.times do |b|
        no = b + 1
        plant_id = repo.get_id(:plant_resources, plant_resource_code: "CLM-#{seq_str}-B#{no}")
        repo.delete_plant_resource(plant_id)
      end
      clm_id = repo.get_id(:plant_resources, plant_resource_code: "CLM-#{seq_str}")
      repo.link_peripherals(clm_id, [])
      plant_id = repo.get_id(:plant_resources, plant_resource_code: "PRN-#{seq_str}")
      repo.delete_plant_resource(plant_id)
      repo.delete_plant_resource(clm_id)
    end
  end

  def create_modules_and_printers # rubocop:disable Metrics/AbcSize
    clm_attrs = { port: 2000, group_incentive: true, login: true, logoff: false, equipment_type: 'robot-nspi', robot_function: 'HTTP-CartonLabel', module_function: 'carton_labelling', ttl: 10_000, cycle_time: 9000, module_action: 'carton_labeling', publishing: true, extended_config: { distro_type: 'seeed_reterm' } }

    130.times do |n|
      seq = n + 1
      seq_str = seq.to_s.rjust(3, '0')
      res = plant_res(printer_type, "PRN-#{seq_str}", "Printer #{seq}") # model etc...
      printer_id = repo.create_child_plant_resource(line_id, res, sys_code: "PRN-#{seq_str}")

      res = plant_res(clm_type, "CLM-#{seq_str}", "NTD #{seq}")
      clm_id = repo.create_child_plant_resource(line_id, res, sys_code: "CLM-#{seq_str}")
      sysres_id = repo.get(:plant_resources, :system_resource_id, clm_id)
      repo.update_system_resource(sysres_id, clm_attrs.merge(ip_address: "192.168.13.#{seq + 10}"))
      # Add buttons (& link to packpoints...)
      4.times do |b|
        no = b + 1
        res = plant_res(btn_type, "CLM-#{seq_str}-B#{no}", "NTD #{seq_str} Button B#{no}")
        repo.create_child_plant_resource(clm_id, res, sys_code: "CLM-#{seq_str}-B#{no}")
      end
      sysres_id = repo.get(:plant_resources, :system_resource_id, printer_id)
      attrs = { ip_address: "192.168.13.#{seq + 150}", connection_type: 'USB', port: 9100, equipment_type: 'zebra', printer_language: 'zpl', pixels_mm: 8, peripheral_model: 'GK420d', module_function: 'NSLD-Printing', ttl: 9000, cycle_time: 9000 }
      repo.update_system_resource(sysres_id, attrs)
      # link printer
      repo.link_a_peripheral(clm_id, sysres_id)
    end
  end

  def plant_res(type, code, desc, represents_plant_resource_id = nil)
    if represents_plant_resource_id.nil?
      ProductionApp::PlantResourceSchema.call(plant_resource_type_id: type, plant_resource_code: code, description: desc)
    else
      ProductionApp::PlantResourceSchema.call(plant_resource_type_id: type, plant_resource_code: code, description: desc, represents_plant_resource_id: represents_plant_resource_id)
    end
  end
end
