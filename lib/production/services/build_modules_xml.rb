# frozen_string_literal: true

module ProductionApp
  class BuildModulesXml < BaseService
    attr_reader :id, :repo

    def initialize
      @repo = ResourceRepo.new
    end

    def call
      modules = repo.system_modules
      servers = repo.system_servers
      xml = build_xml(modules, servers)
      success_response('BuildModulesXml was successful', xml)
    end

    def build_xml(modules, servers) # rubocop:disable Metrics/AbcSize
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.SystemSchema do
          xml.Modules do
            unless servers.empty?
              servers.each do |srv|
                xml.Module(Name: srv[:name],
                           Type: srv[:module_type],
                           Function: srv[:function],
                           Alias: srv[:alias],
                           NetworkInterface: srv[:network_interface],
                           Port: srv[:port],
                           MacAddress: srv[:mac_address],
                           TTL: srv[:ttl],
                           # CycleTime: srv[:cycle_time],
                           Publishing: srv[:publishing],
                           PrinterTypes: srv[:printer_types])
              end
            end
            unless modules.empty?
              modules.each do |ph, ph_mods|
                xml.comment "\n      Packhouse #{ph}\n    "
                ph_mods.each do |mod|
                  key = mod[:module_action]
                  action_set = key.nil? ? {} : Crossbeams::Config::ResourceDefinitions::MODULE_ACTIONS[key.to_sym] || {}
                  if %w[robot_rpi robot_nspi].include?(mod[:module_type])
                    xml.Module(Name: mod[:name],
                               Type: mod[:module_type],
                               Function: mod[:function],
                               Alias: mod[:alias],
                               NetworkInterface: mod[:network_interface],
                               Port: mod[:port],
                               MacAddress: mod[:mac_address],
                               TTL: mod[:ttl],
                               CycleTime: mod[:cycle_time],
                               Publishing: mod[:publishing],
                               Login: mod[:login],
                               Logoff: mod[:logoff],
                               URL: action_set[:url],
                               Par1: action_set[:Par1],
                               Par2: action_set[:Par2],
                               Par3: action_set[:Par3],
                               Par4: action_set[:Par4],
                               Par5: action_set[:Par5],
                               Par6: action_set[:Par6],
                               ReaderID: action_set[:readerid],
                               ContainerType: action_set[:container_type],
                               WeightUnits: action_set[:weight_units],
                               Printer: mod[:printer],
                               PrinterTypes: mod[:printer_types])
                  else
                    # Include a set of button specs for no of labels per button?
                    xml.Module(Name: mod[:name],
                               Type: mod[:module_type],
                               Function: mod[:function],
                               Alias: mod[:alias],
                               NetworkInterface: mod[:network_interface],
                               Port: mod[:port],
                               MacAddress: mod[:mac_address],
                               TTL: mod[:ttl],
                               CycleTime: mod[:cycle_time],
                               Publishing: mod[:publishing],
                               Login: mod[:login],
                               Logoff: mod[:logoff],
                               Printer: mod[:printer],
                               PrinterTypes: mod[:printer_types])
                  end
                end
              end
            end
          end
        end
      end
      builder.to_xml
    end
  end
end
