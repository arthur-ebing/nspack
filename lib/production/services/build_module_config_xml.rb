# frozen_string_literal: true

module ProductionApp
  class BuildModuleConfigXml < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :id, :repo, :alternate_ip, :netmask

    def initialize(id, alternate_ip: nil)
      @id = id
      @alternate_ip = alternate_ip
      @repo = ResourceRepo.new
    end

    def call
      sys_mod = repo.find_system_resource_flat(id)
      server = repo.find_mes_server
      raise Crossbeams::InfoError, 'There is no plant resource defined as a MesServer' if server.nil?

      @netmask = server.extended_config['netmask'] || '255.255.255.0'
      buttons = repo.robot_button_system_resources(sys_mod.plant_resource_id)
      xml = build_xml(sys_mod, buttons, server)
      success_response('BuildModuleConfigXml was successful', xml: xml, module: sys_mod.system_resource_code)
    end

    def build_xml(sys_mod, buttons, server) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return 'No module action defined' if sys_mod.module_action.nil?

      action = Crossbeams::Config::ResourceDefinitions::MODULE_ACTIONS[sys_mod.module_action.to_sym]
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml| # rubocop:disable Metrics/BlockLength
        xml.comment "\n  (C) #{Time.now.year}, NoSoft MesServer XML Setup File\n  "
        xml.SystemSchema do # rubocop:disable Metrics/BlockLength
          xml.Messages do
            xml.MsgQueLength 3500
          end
          xml.Logging do
            xml.LogQueLength 3501
            xml.LogDayCycle 5
            xml.LogImage false
          end
          xml.System do
            xml.Company AppConst::IMPLEMENTATION_OWNER
            xml.LocalInterface alternate_ip || sys_mod.ip_address
            xml.ServerInterface server.ip_address
            xml.ServerPort server.port
            xml.NetMask netmask
            xml.Gateway server.ip_address
            xml.comment "\n        When to use true for lbl store (nspi CLM && publishing?)\n        When true for LineProdUnit???\n        Why do we need sys pwd?\n    "
            xml.CentralLabelStore sys_mod.publishing # nspi CLM
            xml.LineProductionUnit true # ??? CLM?
            xml.SystemPassword AppConst::PROVISION_PW # ????
            xml.Cms false
            xml.Mqtt false
            xml.Debug false
          end

          xml.Devices do
            xml.comment 'Which of these are ALWAYS present, and which are OPTIONAL?'
            xml.Cpu(Name: 'Cpu', Driver: '', Function: 'Temperature', FanOn: 72, FanOff: 35)
            xml.Clock(Name: 'Clock', Driver: '', Function: 'Clock', NetworkInterface: 0, Port: 0)
            xml.Rs232(Name: '/dev/ttyS0', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            xml.Rs232(Name: '/dev/ttyUSB1', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            xml.Usb(Name: '/dev/ttyACM_DEVICE0', Driver: 'usbcom', Function: 'USBIO', NetworkInterface: 0, Port: 0)
            xml.Usb(Name: '/dev/ttyACM_DEVICE1', Driver: 'usbcom', Function: 'USBIO', NetworkInterface: 0, Port: 0)
            xml.Ethernet(Name: 'Eth01', Function: 'tcpserver', NetworkInterface: '', Port: 2000, NetMask: netmask, GateWay: '', TTL: 10_000)
            xml.Ethernet(Name: 'Eth02', Function: 'tcpserver', NetworkInterface: '', Port: 2091, NetMask: netmask, GateWay: '', TTL: 10_000)
            xml.Ethernet(Name: 'Eth03', Function: 'tcpserver', NetworkInterface: '', Port: 2095, NetMask: netmask, GateWay: '', TTL: 10_000)
            xml.Ethernet(Name: 'Eth04', Function: 'httpserver', NetworkInterface: '', Port: 2080, NetMask: netmask, GateWay: '', TTL: 15_000)
          end

          xml.Peripherals do # rubocop:disable Metrics/BlockLength
            # What does this depend on? Does it matter if it is present in all configs? (e.g. Not at Loftus)
            # Perhaps we need scanner defs
            # and modules can choose to include one.
            xml.Scanner(Name: 'RID-01',
                        Type: 'RDM630',
                        Model: 'RDM630',
                        DeviceName: '/dev/ttyS0',
                        ReaderId: 1,
                        ConnectionType: 'RS232',
                        BaudRate: '9600',
                        Parity: 'N',
                        FlowControl: 'N',
                        DataBits: 8,
                        StopBits: 1,
                        BufferSize: 256,
                        StartOfInput: 'STX',
                        EndOfInput: 'ETX',
                        StripStartOfInput: false,
                        StripEndOfInput: false) # ???
            peripherals.each do |p|
              if p.plant_resource_type_code == 'PRINTER'
                xml.Printer(Name: p.system_resource_code,
                            Type: p.equipment_type,
                            Model: p.peripheral_model,
                            DeviceName: '',
                            ConnectionType: p.connection_type,
                            NetworkInterface: alternate_ip || p.ip_address,
                            Port: p.port,
                            Language: p.printer_language,
                            Alias: p.plant_resource_code,
                            Function: p.module_function,
                            TTL: p.ttl,
                            Username: p.print_username,
                            Password: p.print_password,
                            PixelsMM: p.pixels_mm)
              else
                xml.comment "Not yet implemented for #{p.plant_resource_type_code}"
                xml.OtherNotYetDefined p.system_resource_code
              end
            end
          end

          # <Robot
          # 	Name="CLM-01"
          # 	Alias="CartonLabel"
          # 	Function="HTTP-CartonLabel"
          # 	ServerInterface=""
          # 	Port="80"
          # 	RFID="RID-01"
          # 	AccessControl="true"
          # 	TCP="false"
          # 	Scanner=""
          # 	Scale=""
          # 	Printer=""
          # 	TransactionTrigger="Button"
          # 	>
          xml.Robots do # rubocop:disable Metrics/BlockLength
            xml.Robot(Name: sys_mod.system_resource_code,
                      Alias: sys_mod.plant_resource_code,
                      Function: sys_mod.robot_function,
                      ServerInterface: '',
                      Port: 80, # 9296, # --> Webapp port
                      RFID: 'RID-01', # (if sys_mod.login? && not T200?)
                      AccessControl: sys_mod.login,
                      TCP: '', # ???
                      Scanner: '',
                      Scale: '',
                      Printer: '',
                      LabelQuantity: buttons.map { |a| (a.extended_config || {})['no_of_labels_to_print'] }.compact.max || 1,
                      TransactionTrigger: 'Button') do
              if sys_mod.module_action == 'carton_labeling'
                buttons.each_with_index do |button, index|
                  hs = {
                    Name: "B#{index + 1}",
                    Enable: true,
                    Caption: "Button #{index + 1}",
                    LabelQuantity: (button.extended_config || {})['no_of_labels_to_print'] || 1,
                    URL: action[:url],
                    Par1: action[:Par1]
                  }
                  hs[:Par2] = action[:Par2] if action[:Par2]
                  hs[:Par3] = action[:Par3] if action[:Par3]
                  hs[:Par4] = action[:Par4] if action[:Par4]
                  hs[:Par5] = action[:Par5] if action[:Par5]
                  xml.Button(hs)
                  # <Button Name="B1" Enable="true" Caption="Button 1" URL="/messcada/production/carton_labeling?" Par1="device" Par2="identifier" />
                end
              end
            end
            # buttons - specified by resource tree - or implied by module_action...
          end

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
  end
end
