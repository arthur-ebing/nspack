# frozen_string_literal: true

module ProductionApp
  class BuildPeripheralsXml < BaseService
    attr_reader :id, :repo

    def initialize
      @repo = ResourceRepo.new
    end

    def call
      peripherals = repo.system_peripheral_printers
      xml = build_xml(peripherals)
      success_response('BuildPeripheralsXml was successful', xml)
    end

    private

    def build_xml(peripherals) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.SystemSchema do
          xml.Peripherals do
            unless peripherals.empty?
              peripherals.each do |ph, periphs|
                xml.comment "\n      Packhouse #{ph}\n    "
                periphs.each do |prt|
                  ip = prt[:network_interface]
                  ip = repo.usb_printer_ip(prt[:id]) if ip.nil? && prt[:connection_type] == 'USB'
                  # print_key = Crossbeams::Config::ResourceDefinitions::REMOTE_PRINTER_SET[prt[:type]] || prt[:type]
                  print_set = Crossbeams::Config::ResourceDefinitions::PRINTER_SET[prt[:type]][prt[:model]] || {}
                  xml.Printer(Name: prt[:name],
                              Function: prt[:function],
                              Alias: prt[:alias],
                              Type: prt[:connection_type] == 'USB' ? "remote-#{prt[:type]}" : prt[:type],
                              Model: prt[:model],
                              ConnectionType: prt[:connection_type], # Force to TCP ????
                              NetworkInterface: ip, # prt[:network_interface], # Set this to the NTD's ip if this is a USB printer
                              Port: prt[:port],
                              TTL: prt[:ttl],
                              CycleTime: prt[:cycle_time],
                              Language: print_set[:lang],
                              VendorID: prt[:connection_type] == 'USB' ? print_set[:usb_vendor] : '',
                              ProductID: prt[:connection_type] == 'USB' ? print_set[:usb_product] : '',
                              Username: prt[:username],
                              Password: prt[:password],
                              PixelsMM: prt[:pixels_mm])
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
