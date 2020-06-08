# frozen_string_literal: true

module ProductionApp
  class BuildPeripheralsXml < BaseService
    attr_reader :id, :repo

    def initialize
      @repo = ResourceRepo.new
    end

    def call
      peripherals = repo.system_peripherals
      xml = build_xml(peripherals)
      success_response('BuildPeripheralsXml was successful', xml)
    end

    private

    def build_xml(peripherals) # rubocop:disable Metrics/AbcSize
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.SystemSchema do
          xml.Peripherals do
            unless peripherals.empty?
              peripherals.each do |prt|
                xml.Printer(Name: prt[:name],
                            Function: prt[:function],
                            Alias: prt[:alias],
                            Type: prt[:type],
                            Model: prt[:model],
                            ConnectionType: prt[:connection_type],
                            NetworkInterface: prt[:network_interface],
                            Port: prt[:port],
                            TTL: prt[:ttl],
                            CycleTime: prt[:cycle_time],
                            Language: prt[:language],
                            Username: prt[:username],
                            Password: prt[:password],
                            PixelsMM: prt[:pixels_mm])
              end
            end
          end
        end
      end
      builder.to_xml
    end
  end
end
