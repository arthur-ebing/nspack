# frozen_string_literal: true

module Crossbeams
  module Config
    # Store rules for Resource types like how to build resource trees and associations.
    class ResourceDefinitions
      COLOURS = %w[
        #234722
        #326699
        #329932
        #36a864
        #5F98CA
        #62c95f
        #80b8e0
        #90c6b0
        #9580e0
        #993299
        #a8364c
        #c65fc9
        #c79191
        #c791bc
        #c9665f
        #c9915f
        #c9bb5f
        #e0ce7f

        #E76D9A
        #EA6D86
        #EC6E73
        #EA705F
        #E6774C
        #E17B3C
        #DA812B
        #D2881E
        #C78F13
        #B99710
        #AA9F19
        #99A426
        #87AA36
        #70B045
        #57B356
        #36B767
        #05B878
        #06BA8B
        #00BA9C
        #01B8BB
        #02B3CA
        #03B1D6
        #22ADE1
        #47A7EB
        #62A2F2
        #779CF6
        #8A94F9
        #9B90F8
        #A988F5
        #B782F0
        #C27CE7
        #CE77DD
        #D673CE
        #DD6EBF
      ].freeze
      # Icon colours
      # CLR_A = '#234722'
      # CLR_B = '#326699'
      # CLR_C = '#329932'
      # CLR_D = '#36a864'
      # CLR_E = '#5F98CA'
      # CLR_F = '#62c95f'
      # CLR_G = '#80b8e0'
      # CLR_H = '#90c6b0'
      # CLR_I = '#9580e0'
      # CLR_J = '#993299'
      # CLR_K = '#a8364c'
      # CLR_L = '#c65fc9'
      # CLR_M = '#c79191'
      # CLR_N = '#c791bc'
      # CLR_O = '#c9665f'
      # CLR_P = '#c9915f'
      # CLR_Q = '#c9bb5f'
      # CLR_R = '#e0ce7f'
      CLR_A = COLOURS[0]
      CLR_B = COLOURS[1]
      CLR_C = COLOURS[2]
      CLR_D = COLOURS[3]
      CLR_E = COLOURS[4]
      CLR_F = COLOURS[5]
      CLR_G = COLOURS[6]
      CLR_H = COLOURS[7]
      CLR_I = COLOURS[8]
      CLR_J = COLOURS[9]
      CLR_K = COLOURS[10]
      CLR_L = COLOURS[11]
      CLR_M = COLOURS[12]
      CLR_N = COLOURS[13]
      CLR_O = COLOURS[14]
      CLR_P = COLOURS[15]
      CLR_Q = COLOURS[16]
      CLR_R = COLOURS[17]
      CLR_S = COLOURS[18]
      CLR_T = COLOURS[19]
      CLR_U = COLOURS[20]
      CLR_V = COLOURS[21]
      CLR_W = COLOURS[32]
      # CLR_A = COLOURS[20]
      # CLR_B = COLOURS[21]
      # CLR_C = COLOURS[22]
      # CLR_D = COLOURS[23]
      # CLR_E = COLOURS[24]
      # CLR_F = COLOURS[25]
      # CLR_G = COLOURS[26]
      # CLR_H = COLOURS[27]
      # CLR_I = COLOURS[28]
      # CLR_J = COLOURS[29]
      # CLR_K = COLOURS[30]
      # CLR_L = COLOURS[31]
      # CLR_M = COLOURS[32]
      # CLR_N = COLOURS[33]
      # CLR_O = COLOURS[34]
      # CLR_P = COLOURS[35]
      # CLR_Q = COLOURS[36]
      # CLR_R = COLOURS[37]
      # CLR_S = COLOURS[38]
      # CLR_T = COLOURS[39]
      # CLR_U = COLOURS[40]
      # CLR_V = COLOURS[41]
      # rainbow:
      # #E76D9A
      # #EA6D86
      # #EC6E73
      # #EA705F
      # #E6774C
      # #E17B3C
      # #DA812B
      # #D2881E
      # #C78F13
      # #B99710
      # #AA9F19
      # #99A426
      # #87AA36
      # #70B045
      # #57B356
      # #36B767
      # #05B878
      # #06BA8B
      # #00BA9C
      # #01B8BB
      # #02B3CA
      # #03B1D6
      # #22ADE1
      # #62A2F2
      # #47A7EB
      # #779CF6
      # #8A94F9
      # #9B90F8
      # #A988F5
      # #B782F0
      # #C27CE7
      # #CE77DD
      # #D673CE
      # #DD6EBF

      SITE = 'SITE'
      PACKHOUSE = 'PACKHOUSE'
      ROOM = 'ROOM' # (AREA?)
      LINE = 'LINE'
      PRESORTING_UNIT = 'PRESORTING_UNIT'
      DROP = 'DROP'
      PACK_POINT = 'PACK_POINT'
      DROP_TABLE = 'DROP_TABLE'
      ROBOT_BUTTON = 'ROBOT_BUTTON'
      PACKPOINT_BUTTON = 'PACKPOINT_BUTTON'
      CLM_ROBOT = 'CLM_ROBOT'
      BIN_FILLER_ROBOT = 'BIN_FILLER_ROBOT'
      QC_ROBOT = 'QC_ROBOT'
      SCALE_ROBOT = 'SCALE_ROBOT'
      BIN_SCALE_ROBOT = 'BIN_SCALE_ROBOT'
      CARTON_SCALE_ROBOT = 'CARTON_SCALE_ROBOT'
      PALLET_SCALE_ROBOT = 'PALLET_SCALE_ROBOT'
      BIN_FORKLIFT_ROBOT = 'BIN_FORKLIFT_ROBOT'
      PALLETIZING_STATION = 'PALLETIZING_STATION'
      PALLETIZING_BAY = 'PALLETIZING_BAY'
      AUTOPACK_PALLET_BAY = 'AUTOPACK_PALLET_BAY'
      PALLET_FORKLIFT_ROBOT = 'PALLET_FORKLIFT_ROBOT'
      PALLETIZING_ROBOT = 'PALLETIZING_ROBOT'
      BIN_TIPPING_ROBOT = 'BINTIPPING_ROBOT'
      STAGING_TIPPING_ROBOT = 'STAGING_TIPPING_ROBOT'
      BIN_FORKLIFT = 'BIN_FORKLIFT'
      PALLET_FORKLIFT = 'PALLET_FORKLIFT'
      CARTON_VERIFICATION_STATION = 'CARTON_VERIFICATION_STATION'
      CARTON_VERIFICATION_ROBOT = 'CARTON_VERIFICATION_ROBOT'
      BIN_TIPPING_STATION = 'BIN_TIPPING_STATION'
      BIN_VERIFICATION_STATION = 'BIN_VERIFICATION_STATION'
      BIN_VERIFICATION_ROBOT = 'BIN_VERIFICATION_ROBOT'
      PRINT_STATION = 'PRINT_STATION'
      PRINT_STATION_ROBOT = 'PRINT_STATION_ROBOT'
      WEIGHING_STATION = 'WEIGHING_STATION'
      MES_SERVER = 'MES_SERVER'
      CMS_SERVER = 'CMS_SERVER'
      ITPC = 'ITPC'
      SUB_LINE = 'SUB_LINE'
      VLAN = 'VLAN'

      # Peripherals
      SCALE = 'SCALE'
      PRINTER = 'PRINTER'
      SCANNER = 'SCANNER'
      # SCN- : SCANNER (not required as a plant resource)

      # System resource types
      SERVER = 'SERVER'
      MODULE = 'MODULE'
      MODULE_BUTTON = 'MODULE_BUTTON'
      PERIPHERAL = 'PERIPHERAL'
      NETWORK = 'NETWORK'

      ROOT_PLANT_RESOURCE_TYPES = [SITE, BIN_FORKLIFT, PALLET_FORKLIFT, ROOM].freeze

      SYSTEM_RESOURCE_RULES = {
        SERVER => { description: 'Server',
                    computing_device: true,
                    attributes: { ip_address: :string,
                                  sub_types: [MES_SERVER, CMS_SERVER] } },
        NETWORK => { description: 'Network',
                     computing_device: true,
                     attributes: { ip_address: :string,
                                   sub_types: [VLAN] } },
        MODULE => { description: 'Module',
                    computing_device: true,
                    attributes: { ip_address: :string,
                                  sub_types: [CLM_ROBOT,
                                              BIN_FILLER_ROBOT,
                                              QC_ROBOT,
                                              BIN_SCALE_ROBOT,
                                              CARTON_SCALE_ROBOT,
                                              PALLET_SCALE_ROBOT,
                                              CARTON_VERIFICATION_ROBOT,
                                              BIN_VERIFICATION_ROBOT,
                                              BIN_FORKLIFT_ROBOT,
                                              PALLET_FORKLIFT_ROBOT,
                                              PALLETIZING_ROBOT,
                                              BIN_TIPPING_ROBOT,
                                              STAGING_TIPPING_ROBOT,
                                              ITPC] } },
        MODULE_BUTTON => { description: 'Module button',
                           computing_device: true,
                           attributes: { ip_address: :string,
                                         sub_types: [ROBOT_BUTTON] } },
        PERIPHERAL => { description: 'Peripheral',
                        peripheral: true,
                        attributes: { ip_address: :string } }
      }.freeze

      PLANT_RESOURCE_RULES = {
        SITE => { description: 'Site',
                  allowed_children: [PACKHOUSE, ROOM, MES_SERVER, CMS_SERVER, PRESORTING_UNIT],
                  icon: { file: 'globe', colour: CLR_H } },
        MES_SERVER => { description: 'MES Server',
                        allowed_children: [VLAN],
                        icon: { file: 'servers', colour: CLR_J },
                        create_with_system_resource: SERVER,
                        code_prefix: 'SRV-' },
        CMS_SERVER => { description: 'CMS Server',
                        allowed_children: [],
                        icon: { file: 'servers', colour: CLR_P },
                        create_with_system_resource: SERVER,
                        code_prefix: 'SRV-' },
        VLAN => { description: 'VLAN',
                  allowed_children: [],
                  icon: { file: 'load-balancer', colour: CLR_F },
                  create_with_system_resource: NETWORK,
                  code_prefix: 'VLAN-' },
        PACKHOUSE => { description: 'Packhouse',
                       allowed_children: [ROOM,
                                          LINE,
                                          CLM_ROBOT,
                                          BIN_FILLER_ROBOT,
                                          BIN_SCALE_ROBOT,
                                          CARTON_SCALE_ROBOT,
                                          PALLET_SCALE_ROBOT,
                                          QC_ROBOT,
                                          PALLETIZING_STATION,
                                          PALLETIZING_BAY,
                                          AUTOPACK_PALLET_BAY,
                                          SCALE,
                                          PRINTER,
                                          CARTON_VERIFICATION_STATION,
                                          BIN_VERIFICATION_STATION,
                                          WEIGHING_STATION],
                       icon: { file: 'factory', colour: CLR_N } },
        PRESORTING_UNIT => { description: 'Presorting Unit',
                             allowed_children: [],
                             icon: { file: 'shuffle', colour: CLR_W } },
        ROOM => { description: 'Room',
                  allowed_children: [QC_ROBOT, BIN_SCALE_ROBOT, CARTON_SCALE_ROBOT, PALLET_SCALE_ROBOT, SCALE, PRINTER, WEIGHING_STATION],
                  icon: { file: 'home', colour: CLR_K } },
        LINE => { description: 'Line',
                  allowed_children: [SUB_LINE, DROP, PACK_POINT, DROP_TABLE, CLM_ROBOT, BIN_FILLER_ROBOT, QC_ROBOT, PALLETIZING_STATION, AUTOPACK_PALLET_BAY, PALLETIZING_BAY, BIN_TIPPING_STATION, SCALE, PRINTER, PRINT_STATION, ITPC],
                  icon: { file: 'packline', colour: CLR_S } },
        SUB_LINE => { description: 'Sub-Line',
                      allowed_children: [DROP, PACK_POINT, DROP_TABLE, CLM_ROBOT, BIN_FILLER_ROBOT, QC_ROBOT, PALLETIZING_STATION, AUTOPACK_PALLET_BAY, PALLETIZING_BAY, SCALE, PRINTER, PRINT_STATION, ITPC],
                      icon: { file: 'packline', colour: CLR_D } },
        DROP => { description: 'Drop',
                  allowed_children: [PACK_POINT, DROP_TABLE, CLM_ROBOT, BIN_FILLER_ROBOT, BIN_SCALE_ROBOT, CARTON_SCALE_ROBOT, PALLET_SCALE_ROBOT, SCALE, PRINTER],
                  icon: { file: 'packing', colour: CLR_D } },
        PACK_POINT => { description: 'Pack point',
                        packpoint: true,
                        allowed_children: [],
                        icon: { file: 'station', colour: CLR_R } },
        DROP_TABLE => { description: 'Drop table',
                        allowed_children: [PACK_POINT, CLM_ROBOT, BIN_FILLER_ROBOT, BIN_SCALE_ROBOT, CARTON_SCALE_ROBOT, PALLET_SCALE_ROBOT, SCALE, PRINTER],
                        icon: { file: 'packing', colour: CLR_N } },
        ROBOT_BUTTON => { description: 'Robot button',
                          allowed_children: [],
                          icon: { file: 'circle-o', colour: CLR_O },
                          create_with_system_resource: 'MODULE_BUTTON',
                          sequence_without_zero_padding: true,  ## spec no zeros.... (default == 1)
                          code_prefix: '${CODE}-B' }, # prefixed by module name followed by....
        PACKPOINT_BUTTON => { description: 'Robot packpoint button',
                              allowed_children: [],
                              represents: PACK_POINT,
                              icon: { file: 'circle-o', colour: CLR_G },
                              create_with_system_resource: 'MODULE_BUTTON',
                              sequence_without_zero_padding: true,  ## spec no zeros.... (default == 1)
                              code_prefix: '${CODE}-B' }, # prefixed by module name followed by....
        CLM_ROBOT => { description: 'CLM Robot',
                       allowed_children: [ROBOT_BUTTON, PACKPOINT_BUTTON],
                       icon: { file: 'server3', colour: CLR_E },
                       create_with_system_resource: 'MODULE',
                       code_prefix: 'CLM-' },
        BIN_FILLER_ROBOT => { description: 'Bin-filler Robot',
                              allowed_children: [ROBOT_BUTTON],
                              icon: { file: 'server3', colour: CLR_M },
                              create_with_system_resource: 'MODULE',
                              code_prefix: 'BFM-' },
        ITPC => { description: 'ITPC',
                  allowed_children: [],
                  icon: { file: 'sitemap', colour: CLR_Q },
                  create_with_system_resource: 'MODULE',
                  code_prefix: 'ITPC-' },
        #  "DTP-"        // Dedicated pack/tipper...
        # "DPK-"        // Dedicated pack/labelling...
        # "LBL-"        // Label...
        # "CMV-"      // Container movement...
        # "REB-"       // Rebinning (another form of labelling)...
        # "CLM-"         // CLM Standard...
        QC_ROBOT => { description: 'QC Robot',
                      allowed_children: [],
                      icon: { file: 'server3', colour: CLR_L },
                      create_with_system_resource: 'MODULE',
                      code_prefix: 'QCM-' },
        # TODO: deprecate SCALE_ROBOT :: Need to modify existing data at sites first...
        SCALE_ROBOT => { description: 'Scale Robot',
                         allowed_children: [],
                         icon: { file: 'server3', colour: CLR_P },
                         create_with_system_resource: 'MODULE',
                         code_prefix: 'SCM-' },
        BIN_SCALE_ROBOT => { description: 'Bin Scale Robot',
                             allowed_children: [],
                             icon: { file: 'server3', colour: CLR_P },
                             create_with_system_resource: 'MODULE',
                             code_prefix: 'BWM-' },
        CARTON_SCALE_ROBOT => { description: 'Carton Scale Robot',
                                allowed_children: [],
                                icon: { file: 'server3', colour: CLR_W },
                                create_with_system_resource: 'MODULE',
                                code_prefix: 'CWM-' },
        PALLET_SCALE_ROBOT => { description: 'Pallet Scale Robot',
                                allowed_children: [],
                                icon: { file: 'server3', colour: CLR_H },
                                create_with_system_resource: 'MODULE',
                                code_prefix: 'PWM-' },
        BIN_FORKLIFT_ROBOT => { description: 'Bin Forklift Robot',
                                allowed_children: [],
                                icon: { file: 'server3', colour: CLR_F },
                                create_with_system_resource: 'MODULE',
                                code_prefix: 'BMM-' },
        PALLET_FORKLIFT_ROBOT => { description: 'Pallet Forklift Robot',
                                   allowed_children: [],
                                   icon: { file: 'server3', colour: CLR_J },
                                   create_with_system_resource: 'MODULE',
                                   code_prefix: 'PMM-' },
        PALLETIZING_ROBOT => { description: 'Palletizing Robot',
                               allowed_children: [AUTOPACK_PALLET_BAY, PALLETIZING_BAY],
                               icon: { file: 'server3', colour: CLR_T },
                               create_with_system_resource: 'MODULE',
                               code_prefix: 'PTM-' },
        BIN_TIPPING_ROBOT => { description: 'Bintipping Robot',
                               allowed_children: [],
                               icon: { file: 'server3', colour: CLR_Q },
                               create_with_system_resource: 'MODULE',
                               code_prefix: 'BTM-' },
        STAGING_TIPPING_ROBOT => { description: 'Staging Bintipping Robot',
                                   allowed_children: [],
                                   icon: { file: 'server3', colour: CLR_F },
                                   create_with_system_resource: 'MODULE',
                                   code_prefix: 'STM-' },
        BIN_FORKLIFT => { description: 'Bin Forklift',
                          allowed_children: [BIN_FORKLIFT_ROBOT],
                          icon: { file: 'forkishlift', colour: CLR_M } },
        PALLET_FORKLIFT => { description: 'Pallet Forklift',
                             allowed_children: [PALLET_FORKLIFT_ROBOT],
                             icon: { file: 'forkishlift', colour: CLR_M } },
        PALLETIZING_STATION => { description: 'Palletizing Station',
                                 allowed_children: [AUTOPACK_PALLET_BAY, PALLETIZING_BAY, PALLETIZING_ROBOT],
                                 icon: { file: 'cubes', colour: CLR_W } },
        PALLETIZING_BAY => { description: 'Palletizing Bay',
                             allowed_children: [PALLETIZING_ROBOT, SCALE, PRINTER],
                             icon: { file: 'cube', colour: CLR_G } },
        AUTOPACK_PALLET_BAY => { description: 'Palletizing Bay',
                                 allowed_children: [PALLETIZING_ROBOT, SCALE, PRINTER],
                                 icon: { file: 'cube', colour: CLR_V } },
        SCALE => { description: 'Scale',
                   allowed_children: [],
                   create_with_system_resource: PERIPHERAL,
                   icon: { file: 'balance-scale', colour: CLR_I },
                   non_editable_code: true,
                   code_prefix: 'SCL-' },
        SCANNER => { description: 'Scanner',
                     allowed_children: [],
                     create_with_system_resource: PERIPHERAL,
                     icon: { file: 'target', colour: CLR_I },
                     non_editable_code: true,
                     code_prefix: 'SCN-' },
        PRINTER => { description: 'Printer',
                     allowed_children: [],
                     create_with_system_resource: PERIPHERAL,
                     icon: { file: 'printer', colour: CLR_A },
                     non_editable_code: true,
                     code_prefix: 'PRN-' },
        # QC PERIPHERALS... FTA, RFM
        CARTON_VERIFICATION_STATION => { description: 'Carton-verification station',
                                         allowed_children: [CARTON_VERIFICATION_ROBOT, PRINTER],
                                         icon: { file: 'tag', colour: CLR_B } },
        CARTON_VERIFICATION_ROBOT => { description: 'Carton verification Robot',
                                       allowed_children: [ROBOT_BUTTON],
                                       icon: { file: 'server3', colour: CLR_L },
                                       create_with_system_resource: 'MODULE',
                                       code_prefix: 'CVM-' },
        BIN_TIPPING_STATION => { description: 'Bin-tipping station',
                                 allowed_children: [BIN_TIPPING_ROBOT, STAGING_TIPPING_ROBOT, SCALE],
                                 icon: { file: 'cog', colour: CLR_U } },
        BIN_VERIFICATION_STATION => { description: 'Bin-verification station',
                                      allowed_children: [BIN_VERIFICATION_ROBOT, PRINTER],
                                      icon: { file: 'tag', colour: CLR_B } },
        BIN_VERIFICATION_ROBOT => { description: 'Bin verification Robot',
                                    allowed_children: [ROBOT_BUTTON],
                                    icon: { file: 'server3', colour: CLR_C },
                                    create_with_system_resource: 'MODULE',
                                    code_prefix: 'BVM-' },
        WEIGHING_STATION => { description: 'Weighing station',
                              allowed_children: [BIN_SCALE_ROBOT, CARTON_SCALE_ROBOT, PALLET_SCALE_ROBOT, SCALE, PRINTER],
                              icon: { file: 'square', colour: CLR_W } },
        PRINT_STATION => { description: 'Print station',
                           allowed_children: [PRINT_STATION_ROBOT, PRINTER],
                           icon: { file: 'square-o', colour: CLR_J } },
        PRINT_STATION_ROBOT => { description: 'Print station Robot',
                                 allowed_children: [],
                                 icon: { file: 'server3', colour: CLR_V },
                                 create_with_system_resource: 'MODULE',
                                 code_prefix: 'PSM-' }
      }.freeze

      MODULE_ACTIONS = {
        server: {},
        carton_palletizing: {
          url: '',
          Par1: '',
          Par2: '',
          Par3: '',
          Par4: '',
          Par5: '',
          ReaderID: '',
          ContainerType: '',
          WeightUnits: ''
        },
        pallet_movement: {
          url: '',
          Par1: '',
          Par2: '',
          Par3: '',
          Par4: '',
          Par5: '',
          ReaderID: '',
          ContainerType: '',
          WeightUnits: ''
        },
        bin_tipping: {
          url: '/messcada/rmt/bin_tipping?',
          Par1: 'device',
          Par2: 'bin_number',
          Par3: 'identifier',
          Par4: 'gross_weight',
          Par5: 'measurement_unit',
          ReaderID: '',
          ContainerType: 'bin',
          WeightUnits: 'Kg',
          transaction_trigger: 'Scanner'
        },
        bin_tipping_weighing: {
          url: '/messcada/rmt/bin_tipping/weighing?',
          Par1: 'device',
          Par2: 'bin_number',
          Par3: 'identifier',
          Par4: 'gross_weight',
          Par5: 'measurement_unit',
          ReaderID: '',
          ContainerType: 'bin',
          WeightUnits: 'Kg'
        },
        multi_bin_tipping_weighing: {
          url: '/messcada/rmt/bin_tipping/multi_bin_weighing?',
          Par1: 'device',
          Par2: 'bin_number',
          Par3: 'identifier',
          Par4: 'gross_weight',
          Par5: 'measurement_unit',
          ReaderID: '',
          ContainerType: 'bin',
          WeightUnits: 'Kg'
        },
        carton_labeling: {
          url: '/messcada/production/carton_labeling?',
          Par1: 'device',
          Par2: 'card_reader',
          Par3: 'identifier',
          ReaderID: '',
          ContainerType: 'carton',
          WeightUnits: 'Kg'
        },
        carton_verification: {
          url: '/messcada/production/carton_verification?',
          Par1: 'device',
          Par2: 'carton_number',
          Par3: '',
          Par4: '',
          Par5: '',
          ReaderID: '',
          ContainerType: 'carton',
          WeightUnits: 'Kg'
        },
        carton_verification_weighing_labeling: {
          url: '/messcada/production/carton_verification/weighing/labeling?',
          Par1: 'device',
          Par2: 'carton_number',
          Par3: 'gross_weight',
          Par4: 'measurement_unit',
          Par5: 'card_reader',
          Par6: 'identifier',
          ReaderID: '',
          ContainerType: 'carton',
          WeightUnits: 'Kg'
        },
        pallet_weighing: {
          url: '/messcada/fg/pallet_weighing?',
          Par1: 'device',
          Par2: 'bin_number',
          Par3: 'gross_weight',
          Par4: 'measurement_unit',
          Par5: '',
          ReaderID: '',
          ContainerType: 'bin',
          WeightUnits: 'Kg'
        }
      }.freeze

      # Change ROBOT to NTD? (NoSoft Terminal Device)
      MODULE_EQUIPMENT_TYPE_MESSERVER = 'messerver'
      MODULE_EQUIPMENT_TYPE_CMSSERVER = 'cmsserver'
      MODULE_EQUIPMENT_TYPE_NSPI = 'robot-nspi'
      MODULE_EQUIPMENT_TYPE_RPI = 'robot-rpi'
      MODULE_EQUIPMENT_TYPE_RT200 = 'robot-T200'
      MODULE_EQUIPMENT_TYPE_RT210 = 'robot-T210'
      MODULE_EQUIPMENT_TYPE_ITPC = 'ITPC'

      MODULE_EQUIPMENT_TYPES = [
        ['MES Server', MODULE_EQUIPMENT_TYPE_MESSERVER],
        ['CMS Server', MODULE_EQUIPMENT_TYPE_CMSSERVER],
        ['Standard NoSoft RPi NTD (robot-nspi)', MODULE_EQUIPMENT_TYPE_NSPI],
        ['Client-built  RPi device (robot-rpi)', MODULE_EQUIPMENT_TYPE_RPI],
        ['Radical T200/T201 robot - Requires a MAC Address (robot-T200)', MODULE_EQUIPMENT_TYPE_RT200],
        ['Radical T210 Java robot (robot-T210)', MODULE_EQUIPMENT_TYPE_RT210],
        ['ITPC server', MODULE_EQUIPMENT_TYPE_ITPC]
      ].freeze

      MODULE_DISTRO_TYPE_VM = 'rpi_vm'
      MODULE_DISTRO_TYPE_PI = 'rpi_3b+'
      MODULE_DISTRO_TYPE_RETERM = 'seeed_reterm'
      MODULE_DISTRO_TYPE_ITPC = 'itpc'
      MODULE_DISTRO_TYPE_RAD = 'radical'
      # radUDP, radJSON, browser?, android

      MODULE_DISTRO_TYPES = [
        ['Virtual Raspbian', MODULE_DISTRO_TYPE_VM],
        ['Raspberry pi 3B+', MODULE_DISTRO_TYPE_PI],
        ['Seeed reTerminal', MODULE_DISTRO_TYPE_RETERM],
        ['ITPC', MODULE_DISTRO_TYPE_ITPC],
        ['Radical', MODULE_DISTRO_TYPE_RAD]
      ].freeze

      MODULE_ROBOT_FUNCTIONS = %w[
        HTTP-BinTip
        HTTP-BinVerification
        HTTP-CartonLabel
        HTTP-PalletBuildup
        HTTP-PalletBuildup-SplitScreen
        HTTP-PalletWeighing
        HTTP-RmtBinWeighing
        Server
      ].freeze

      REMOTE_PRINTER_SET = { 'remote-argox' => 'argox', 'remote-datamax' => 'datamax', 'remote-zebra' => 'zebra' }.freeze
      PRINTER_SET = {
        'argox' => {
          'AR-O4-250' => { lang: 'pplz', usb_vendor: '1664', usb_product: '0D10' },
          'AR-D4-250' => { lang: 'pplz', usb_vendor: '1664', usb_product: '0E10' }
        },
        'zebra' => {
          'GK420d' => { lang: 'zpl', usb_vendor: '0a5f', usb_product: '0080' },
          'ZD230' => { lang: 'zpl', usb_vendor: '0a5f', usb_product: '0166' },
          'ZD420' => { lang: 'zpl', usb_vendor: '0a5f', usb_product: '0120' }
        },
        'datamax' => {
          'datamax' => { lang: 'pplz', usb_vendor: '', usb_product: '' }
        }
      }.freeze
      # printer:
      # Labelling
      # carton_label

      #   {
      #     url: '/messcada/hr/register_id?',
      #     p1: 'device',
      #     p2: 'card_reader',
      #     p3: 'value',
      #     p4: null,
      #     p5: null,
      #     p6: null,
      #   },
      #   {
      #     url: '/messcada/hr/logon?',
      #     p1: 'device',
      #     p2: 'card_reader',
      #     p3: 'identifier',
      #     p4: null,
      #     p5: null,
      #     p6: null,
      #   },
      #   {
      #     url: '/messcada/hr/logoff?',
      #     p1: 'device',
      #     p2: 'card_reader',
      #     p3: 'identifier',
      #     p4: null,
      #     p5: null,
      #     p6: null,
      #   },
      #   {
      #     url: '/messcada/carton_palletizing/scan_carton?',
      #     p1: 'device',
      #     p2: 'reader_id',
      #     p3: 'identifier',
      #     p4: 'carton_number',
      #     p5: null,
      #     p6: null,
      #   },
      #   {
      #     url: '/messcada/carton_palletizing/qc_out?',
      #     p1: 'device',
      #     p2: 'reader_id',
      #     p3: 'identifier',
      #     p4: null,
      #     p5: null,
      #     p6: null,
      #   },
      #   {
      #     url: '/messcada/carton_palletizing/return_to_bay?',
      #     p1: 'device',
      #     p2: 'reader_id',
      #     p3: 'identifier',
      #     p4: null,
      #     p5: null,
      #     p6: null,
      #   },
      #   {
      #     url: '/messcada/carton_palletizing/refresh?',
      #     p1: 'device',
      #     p2: 'reader_id',
      #     p3: 'identifier',
      #     p4: null,
      #     p5: null,
      #     p6: null,
      #   },
      #   {
      #     url: '/messcada/carton_palletizing/complete?',
      #     p1: 'device',
      #     p2: 'reader_id',
      #     p3: 'identifier',
      #     p4: null,
      #     p5: null,
      #     p6: null,
      #   },
      # ];

      # FTP..
      # add module with robot, use prefix for mod only & check db for next value
      # What happens if XML config has srv-01:clm-01 and srv-02:clm-04 and clm-01 is renamed to clm-03 and clm-04 becomes clm-01 ?
      # MODULE could be CLM, SCM, QCM.. (get prefix from plant - "P:" or module_type..)

      def self.refresh_plant_resource_types # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        cnt = 0
        repo = BaseRepo.new
        representers = {}
        PLANT_RESOURCE_RULES.each_key do |key|
          next if repo.exists?(:plant_resource_types, plant_resource_type_code: key)

          icon = PLANT_RESOURCE_RULES[key][:icon].nil? ? nil : PLANT_RESOURCE_RULES[key][:icon].values.join(',')

          id = repo.create(:plant_resource_types,
                           plant_resource_type_code: key,
                           icon: icon,
                           description: PLANT_RESOURCE_RULES[key][:description],
                           packpoint: PLANT_RESOURCE_RULES[key][:packpoint] || false)

          representers[id] = PLANT_RESOURCE_RULES[key][:represents] if PLANT_RESOURCE_RULES[key][:represents]
          cnt += 1
        end

        SYSTEM_RESOURCE_RULES.each_key do |key|
          next if repo.exists?(:system_resource_types, system_resource_type_code: key)

          repo.create(:system_resource_types,
                      system_resource_type_code: key,
                      icon: 'microchip',
                      computing_device: SYSTEM_RESOURCE_RULES[key][:computing_device] || false,
                      peripheral: SYSTEM_RESOURCE_RULES[key][:peripheral] || false,
                      description: SYSTEM_RESOURCE_RULES[key][:description])
          cnt += 1
        end

        # If one resource represents another, set the id after all types have been added.
        representers.each do |id, type_code|
          type_id = DB[:plant_resource_types].where(plant_resource_type_code: type_code).get(:id)
          DB[:plant_resource_types].where(id: id).update(represents_plant_resource_type_id: type_id)
        end

        if cnt.zero?
          'There are no new resource types to add'
        else
          desc = cnt == 1 ? 'type was' : 'types were'
          "#{cnt} new resource #{desc} added"
        end
      end

      def self.refresh_icons
        repo = BaseRepo.new
        PLANT_RESOURCE_RULES.each_key do |key|
          resource = repo.where_hash(:plant_resource_types, plant_resource_type_code: key)

          icon = PLANT_RESOURCE_RULES[key][:icon].nil? ? nil : PLANT_RESOURCE_RULES[key][:icon].values.join(',')

          repo.update(:plant_resource_types, resource[:id], icon: icon)
        end
      end

      def self.can_have_children?(plant_resource_type_code)
        !PLANT_RESOURCE_RULES[plant_resource_type_code][:allowed_children].empty?
      end

      def self.can_have_children_of_type?(plant_resource_type_code, child_type)
        PLANT_RESOURCE_RULES[plant_resource_type_code][:allowed_children].include?(child_type)
      end

      # Get a list of plant resource type codes that are allowed to serve as a parent of the given resource type.
      def self.allowed_parent_types(plant_resource_type_code)
        PLANT_RESOURCE_RULES.select { |_, v| v[:allowed_children].include?(plant_resource_type_code) }.map { |k, _| k }
      end

      def self.peripheral_type_codes
        PLANT_RESOURCE_RULES.select { |_, v| v[:create_with_system_resource] == PERIPHERAL }.keys
      end

      def self.can_be_provisioned?(distro_type)
        %w[rpi_vm rpi_3b+ seeed_reterm].include?(distro_type)
      end
    end
  end
end
