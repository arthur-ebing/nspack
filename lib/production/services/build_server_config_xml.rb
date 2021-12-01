# frozen_string_literal: true

module ProductionApp
  class BuildServerConfigXml < BaseService
    attr_reader :id, :repo, :alternate_ip, :sys_mod, :netmask, :gateway

    def initialize(id, alternate_ip: nil)
      @id = id
      @alternate_ip = alternate_ip
      @repo = ResourceRepo.new
    end

    def call
      @sys_mod = repo.find_system_resource_flat(id)

      @netmask = sys_mod.extended_config['netmask'] || '255.255.255.0'
      @gateway = sys_mod.extended_config['gateway'] # TODO: read vlans to build ethernet ips
      xml = build_xml(sys_mod)
      success_response('BuildModuleConfigXml was successful', xml: xml, module: sys_mod.system_resource_code)
    end

    def build_xml(sys_mod) # rubocop:disable Metrics/AbcSize
      return 'No module action defined' if sys_mod.module_action.nil?

      # action = Crossbeams::Config::ResourceDefinitions::MODULE_ACTIONS[sys_mod.module_action.to_sym]
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml| # rubocop:disable Metrics/BlockLength
        xml.comment "\n  (C) #{Time.now.year}, NoSoft MesServer XML Setup File\n  "
        xml.SystemSchema do # rubocop:disable Metrics/BlockLength
          xml.Messages do
            xml.MsgQueLength 3500
          end
          xml.Logging do
            xml.LogQueLength 3501
            xml.LogDayCycle 5
            xml.LogImage false # for server?
          end
          xml.System do
            xml.Company AppConst::IMPLEMENTATION_OWNER
            xml.LocalInterface alternate_ip || sys_mod.ip_address
            xml.ServerInterface sys_mod.ip_address
            # xml.ServerPort sys_mod.port # for server?
            # xml.NetMask netmask # for server?
            # xml.Gateway gateway # for server?
            xml.comment "\n        When to use true for lbl store (always false for server?)\n        When true for LineProdUnit???\n        Why do we need sys pwd?\n    "
            xml.CentralLabelStore sys_mod.publishing # false?
            xml.LineProductionUnit true # ??? CLM?
            # xml.SystemPassword AppConst::PROVISION_PW # ????
            xml.Cms false
            xml.Mqtt false
            xml.Debug false
          end

          xml.Devices do
            xml.comment 'Which of these are ALWAYS present, and which are OPTIONAL?'
            # xml.Cpu(Name: 'Cpu', Driver: '', Function: 'Temperature', FanOn: 72, FanOff: 35) # for server?
            xml.Clock(Name: 'Clock', Driver: '', Function: 'Clock', NetworkInterface: 0, Port: 0)
            # if for_reterm
            #   xml.Rs232(Name: '/dev/ttyAMA0', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            # else # pi3
            #   xml.Rs232(Name: '/dev/ttyS0', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            # end
            # xml.Rs232(Name: '/dev/ttyUSB1', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            # xml.Usb(Name: '/dev/ttyACM_DEVICE0', Driver: 'usbcom', Function: 'USBIO', NetworkInterface: 0, Port: 0)
            # xml.Usb(Name: '/dev/ttyACM_DEVICE1', Driver: 'usbcom', Function: 'USBIO', NetworkInterface: 0, Port: 0)
            xml.Ethernet(Name: 'Eth01', Function: 'tcpserver', NetworkInterface: '', Port: 2000, NetMask: netmask, GateWay: '', TTL: 10_000) # FIXME: gateways may need to be set for vlan?
            xml.Ethernet(Name: 'Eth02', Function: 'tcpserver', NetworkInterface: '', Port: 2091, NetMask: netmask, GateWay: '', TTL: 10_000)
            xml.Ethernet(Name: 'Eth03', Function: 'tcpserver', NetworkInterface: '', Port: 2095, NetMask: netmask, GateWay: '', TTL: 10_000)
            xml.Ethernet(Name: 'Eth04', Function: 'httpserver', NetworkInterface: '', Port: 2080, NetMask: netmask, GateWay: '', TTL: 15_000)
            xml.comment "\n        When VLANs are defined for the server, their Ethernet elements should appear here)\n    "
          end

          xml.Peripherals
          xml.Modules
        end
      end
      builder.to_xml # (save_with: Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS | Nokogiri::XML::Node::SaveOptions::FORMAT)
    end

    def peripherals
      plant_id = repo.get_id(:plant_resources, system_resource_id: id)
      ids = repo.select_values(:plant_resources_system_resources, :system_resource_id, plant_resource_id: plant_id)
      return [] if ids.empty?

      ids.map { |s_id| repo.find_system_resource_flat(s_id) }
    end

    def for_reterm
      @for_reterm ||= sys_mod.extended_config['distro_type'] == Crossbeams::Config::ResourceDefinitions::MODULE_DISTRO_TYPE_RETERM
    end
  end
end
