# frozen_string_literal: true

module ProductionApp
  class BuildModuleConfigXml < BaseService
    attr_reader :id, :repo, :alternate_ip, :sys_mod, :netmask, :gateway

    def initialize(id, alternate_ip: nil)
      @id = id
      @alternate_ip = alternate_ip
      @repo = ResourceRepo.new
    end

    def call # rubocop:disable Metrics/AbcSize
      @sys_mod = repo.find_system_resource_flat(id)
      server = repo.find_mes_server
      raise Crossbeams::InfoError, 'There is no plant resource defined as a MesServer' if server.nil?
      raise Crossbeams::InfoError, 'Distro type has not been set' unless (sys_mod.extended_config || {})['distro_type']

      @netmask = server.extended_config['netmask'] || '255.255.255.0'
      @gateway = server.extended_config['gateway'] # TODO: set to vlan gateway if applicable
      @gateway = nil if @gateway == server.ip_address
      # Check if CLM has a vlan set & get mask + gateway from there...
      buttons = repo.robot_button_system_resources(sys_mod.plant_resource_id)
      xml = build_xml(sys_mod, buttons, server)
      success_response('BuildModuleConfigXml was successful', xml: xml, module: sys_mod.system_resource_code)
    end

    def build_xml(sys_mod, buttons, server) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      return 'No module action defined' if sys_mod.module_action.nil?

      net_interface = alternate_ip || sys_mod.ip_address unless gateway.nil?
      dev_netmask = net_interface.nil? ? nil : netmask
      robot_peripherals = {}
      action = Crossbeams::Config::ResourceDefinitions::MODULE_ACTIONS[sys_mod.module_action.to_sym]
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.comment "\n  (C) #{Time.now.year}, NoSoft MesServer XML Setup File\n  "
        xml.SystemSchema do
          xml.Messages do
            xml.MsgQueLength 3500
          end
          xml.Logging do
            xml.LogQueLength 3501
            xml.LogDayCycle 5
            xml.LogImage false
          end
          xml.System do
            xml.Company AppConst::CLIENT_FULL_NAME
            xml.AutoConfigure false
            xml.LocalInterface alternate_ip || sys_mod.ip_address
            xml.ServerInterface server.ip_address
            xml.ServerPort server.port
            xml.NetMask netmask
            xml.GateWay gateway
            # xml.comment "\n        When to use true for lbl store (nspi CLM && publishing?)\n        When true for LineProdUnit???\n        Why do we need sys pwd?\n    "
            xml.CentralLabelStore sys_mod.publishing # nspi CLM
            xml.LineProductionUnit true
            xml.SystemPassword AppConst::PROVISION_PW # ????
            xml.Cms false
            xml.Mqtt false
            xml.SystemDebug false
          end

          xml.Devices do
            xml.comment 'Which of these are ALWAYS present, and which are OPTIONAL?'
            xml.Cpu(Name: 'Cpu', Driver: '', Function: 'Temperature', FanOn: 72, FanOff: 35)
            xml.Clock(Name: 'Clock', Driver: '', Function: 'Clock', NetworkInterface: 0, Port: 0)
            if for_reterm
              xml.Rs232(Name: '/dev/ttyAMA0', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            else # pi3
              xml.Rs232(Name: '/dev/ttyS0', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            end
            xml.Rs232(Name: '/dev/ttyUSB1', Driver: 'jssc', Function: 'RS232', NetworkInterface: 0, Port: 0)
            xml.Usb(Name: '/dev/ttyACM_DEVICE0', Driver: 'usbcom', Function: 'USBIO', NetworkInterface: 0, Port: 0)
            xml.Usb(Name: '/dev/ttyACM_DEVICE1', Driver: 'usbcom', Function: 'USBIO', NetworkInterface: 0, Port: 0)
            xml.Ethernet(Name: 'Eth01', Function: 'tcpserver', NetworkInterface: net_interface, Port: 2000, NetMask: dev_netmask, GateWay: gateway, TTL: 10_000) # FIXME: gateways may need to be set for vlan?
            xml.Ethernet(Name: 'Eth02', Function: 'tcpserver', NetworkInterface: net_interface, Port: 2091, NetMask: dev_netmask, GateWay: gateway, TTL: 10_000)
            xml.Ethernet(Name: 'Eth03', Function: 'tcpserver', NetworkInterface: net_interface, Port: 2095, NetMask: dev_netmask, GateWay: gateway, TTL: 10_000)
            xml.Ethernet(Name: 'Eth04', Function: 'httpserver', NetworkInterface: net_interface, Port: 2080, NetMask: dev_netmask, GateWay: gateway, TTL: 15_000)
          end

          xml.Peripherals do
            # What does this depend on? Does it matter if it is present in all configs? (e.g. Not at Loftus)
            # Perhaps we need scanner defs
            # and modules can choose to include one.
            # if .login...
            xml.Scanner(Name: 'RID-01',
                        Type: 'RDM630',
                        Model: 'RDM630',
                        DeviceName: for_reterm ? '/dev/ttyAMA0' : '/dev/ttyS0',
                        ReaderID: 1,
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

            scanner_count = 0
            peripherals.each do |p|
              (robot_peripherals[p.plant_resource_type_code] ||= []) << p.plant_resource_code
              case p.plant_resource_type_code
              when Crossbeams::Config::ResourceDefinitions::PRINTER
                # print_key = Crossbeams::Config::ResourceDefinitions::REMOTE_PRINTER_SET[p.equipment_type] || p.equipment_type
                print_set = Crossbeams::Config::ResourceDefinitions::PRINTER_SET[p.equipment_type][p.peripheral_model]
                xml.Printer(Name: p.system_resource_code,
                            Type: p.equipment_type.sub('remote-', ''),
                            Model: p.peripheral_model,
                            DeviceName: '',
                            ConnectionType: p.connection_type,
                            NetworkInterface: p.connection_type == 'USB' ? '' : alternate_ip || p.ip_address,
                            Port: p.connection_type == 'USB' ? '' : p.port,
                            Language: print_set[:lang],
                            VendorID: p.connection_type == 'USB' ? print_set[:usb_vendor] : '',
                            ProductID: p.connection_type == 'USB' ? print_set[:usb_product] : '',
                            Alias: p.plant_resource_code,
                            Function: p.module_function,
                            TTL: p.ttl,
                            Username: p.print_username,
                            Password: p.print_password,
                            PixelsMM: p.pixels_mm)
              when Crossbeams::Config::ResourceDefinitions::SCANNER
                scanner_count += 1
                scanner_hash = { Name: p.system_resource_code,
                                 Type: p.equipment_type, # USBCOM
                                 Model: p.peripheral_model, # GFS4400
                                 ReaderID: scanner_count,
                                 ConnectionType: p.connection_type,
                                 BufferSize: (p.extended_config || {})['buffer_size'] || '256',
                                 StartOfInput: (p.extended_config || {})['start_of_input'] || '', # STX, ''
                                 EndOfInput: (p.extended_config || {})['end_of_input'] || 'CR', # ETX, '', CR, CRLF
                                 StripStartOfInput: (p.extended_config || {})['strip_start_of_input'] || 'true',
                                 StripEndOfInput: (p.extended_config || {})['strip_end_of_input'] || 'true' }
                if p.connection_type == 'TCP'
                  scanner_hash[:DeviceName] = ''
                  scanner_hash[:NetworkInterface] = alternate_ip || p.ip_address
                  scanner_hash[:Port] = p.port
                else
                  scanner_hash[:DeviceName] = "/dev/ttyACM_DEVICE#{scanner_count - 1}"
                end
                xml.Scanner(scanner_hash)
              when Crossbeams::Config::ResourceDefinitions::SCALE
                # <Scale    Name="SCL-01"  Type="MicroA12E" 	Model="MicroA12E" 	DeviceName="/dev/ttyUSB0" ConnectionType="RS232" BufferSize="256" BaudRate="9600" Parity="N" FlowControl="N" DataBits="8" StopBits="1" StartOfInput=""  EndOfInput="CRLF" StripStartOfInput="true" StripEndOfInput="true"  MinWeight="50" MaxWeight="1000" Unit="kg" Debug="false" />
                xml.Scale(Name: p.system_resource_code,
                          Type: p.equipment_type,
                          Model: p.peripheral_model,
                          DeviceName: '/dev/ttyUSB0',
                          ConnectionType: p.connection_type, # RS232 / tcp
                          BufferSize: (p.extended_config || {})['buffer_size'] || '256',
                          StartOfInput: (p.extended_config || {})['start_of_input'] || '',
                          EndOfInput: (p.extended_config || {})['end_of_input'] || 'CR',
                          StripStartOfInput: (p.extended_config || {})['strip_start_of_input'] || 'true',
                          StripEndOfInput: (p.extended_config || {})['strip_end_of_input'] || 'true',
                          BaudRate: (p.extended_config || {})['baud_rate'] || 9600,
                          Parity: (p.extended_config || {})['parity'] || 'N',
                          FlowControl: (p.extended_config || {})['flow_control'] || 'N',
                          DataBits: (p.extended_config || {})['data_bits'] || 8,
                          StopBits: (p.extended_config || {})['stop_bits'] || 1,
                          MinWeight: 50,
                          MaxWeight: sys_mod.system_resource_code.start_with?('B') ? 550 : 1800,  # Bin weighing max is 550, pallet weighing 1800.
                          Unit: 'kg',
                          Debug: false)
                # NetworkInterface: alternate_ip || p.ip_address, - currently not required, but TCP scale is possible
                # Port: p.port,
                # VendorID: p.connection_type == 'USB' ? print_set[:usb_vendor] : '',
                # ProductID: p.connection_type == 'USB' ? print_set[:usb_product] : '',
                # Alias: p.plant_resource_code,
                # Function: p.module_function)
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
          xml.Robots do
            trigger = action[:transaction_trigger] || 'Button' # NB. PSM has no trigger?
            robot_attr = {
              Name: sys_mod.system_resource_code,
              Alias: sys_mod.plant_resource_code,
              Function: sys_mod.robot_function,
              ServerInterface: '',
              Port: 80, # 9296, # --> Webapp port
              RFID: 'RID-01', # (if sys_mod.login? && not T200?)
              AccessControl: sys_mod.login,
              TCP: false,
              LabelQuantity: buttons.map { |a| (a.extended_config || {})['no_of_labels_to_print'] }.compact.max || 1,
              TransactionTrigger: trigger
            }
            robot_attr[:Scanner] = (robot_peripherals[Crossbeams::Config::ResourceDefinitions::SCANNER] || []).join(',')
            robot_attr[:Scale] = (robot_peripherals[Crossbeams::Config::ResourceDefinitions::SCALE] || []).join(',')
            robot_attr[:Printer] = (robot_peripherals[Crossbeams::Config::ResourceDefinitions::PRINTER] || []).join(',')
            # IF url belons up here and not on button...
            action_detail = Crossbeams::Config::ResourceDefinitions::MODULE_ACTIONS[sys_mod.module_action.to_sym]
            if action_detail[:url_type] == :scan
              robot_attr[:URL] = action_detail[:url]
              robot_attr[:Par1] = action_detail[:Par1]
              robot_attr[:Par2] = action_detail[:Par2]
              robot_attr[:Par3] = action_detail[:Par3]
              robot_attr[:Par4] = action_detail[:Par4]
              robot_attr[:Par5] = action_detail[:Par5]
              robot_attr[:Par6] = action_detail[:Par6]
            end
            xml.Robot(robot_attr) do
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
              else
                6.times { |n| xml.Button(Name: "B#{n + 1}", Enable: false, Caption: '', URL: '', Par1: '', Par2: '') }
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

    def for_reterm
      @for_reterm ||= sys_mod.extended_config['distro_type'] == Crossbeams::Config::ResourceDefinitions::MODULE_DISTRO_TYPE_RETERM
    end
  end
end
