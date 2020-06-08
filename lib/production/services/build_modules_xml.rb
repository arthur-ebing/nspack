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
              modules.each do |mod|
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
                           URL: mod[:url],
                           Par1: mod[:par1],
                           Par2: mod[:par2],
                           Par3: mod[:par3],
                           Par4: mod[:par4],
                           Par5: mod[:par5],
                           ReaderID: mod[:readerid],
                           ContainerType: mod[:container_type],
                           WeightUnits: mod[:weight_units],
                           Printer: mod[:printer],
                           PrinterTypes: mod[:printer_types])
              end
            end
          end
        end
      end
      builder.to_xml
    end
  end
end
