# frozen_string_literal: true

module ProductionApp
  class BuildModulesXml < BaseService
    attr_reader :id, :repo

    def initialize
      @repo = ResourceRepo.new
    end

    def call
      modules = repo.system_modules
      xml = build_xml(modules)
      success_response('BuildModulesXml was successful', xml)
    end

    def build_xml(modules) # rubocop:disable Metrics/AbcSize
      builder = Nokogiri::XML::Builder.new do |xml| # rubocop:disable Metrics/BlockLength
        xml.SystemSchema do # rubocop:disable Metrics/BlockLength
          xml.Modules do # rubocop:disable Metrics/BlockLength
            unless modules.empty?
              modules.each do |mod| # rubocop:disable Metrics/BlockLength
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
      builder.to_xml
    end
  end
end
