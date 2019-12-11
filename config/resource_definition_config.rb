# frozen_string_literal: true

module Crossbeams
  module Config
    # Store rules for Resource types like how to build resource trees and associations.
    class ResourceDefinitions # rubocop:disable Metrics/ClassLength
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
        #62A2F2
        #47A7EB
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
      DROP = 'DROP'
      DROP_STATION = 'DROP_STATION'
      DROP_TABLE = 'DROP_TABLE'
      ROBOT_BUTTON = 'ROBOT_BUTTON'
      CLM_ROBOT = 'CLM_ROBOT'
      QC_ROBOT = 'QC_ROBOT'
      SCALE_ROBOT = 'SCALE_ROBOT'
      FORKLIFT_ROBOT = 'FORKLIFT_ROBOT'
      PALLETIZING_ROBOT = 'PALLETIZING_ROBOT'
      BIN_TIPPING_ROBOT = 'BINTIPPING_ROBOT'
      FORKLIFT = 'FORKLIFT'
      PALLETIZING_BAY = 'PALLETIZING_BAY'
      BIN_TIPPING_STATION = 'BIN_TIPPING_STATION'
      BIN_VERIFICATION_STATION = 'BIN_VERIFICATION_STATION'
      BIN_VERIFICATION_ROBOT = 'BIN_VERIFICATION_ROBOT'
      PRINT_STATION = 'PRINT_STATION'
      PRINT_STATION_ROBOT = 'PRINT_STATION_ROBOT'
      WEIGHING_STATION = 'WEIGHING_STATION'

      # Peripherals
      SCALE = 'SCALE'
      PRINTER = 'PRINTER'
      # SCN- : SCANNER (not required as a plant resource)

      # System resource types
      SERVER = 'SERVER'
      MODULE = 'MODULE'
      MODULE_BUTTON = 'MODULE_BUTTON'
      PERIPHERAL = 'PERIPHERAL'

      ROOT_PLANT_RESOURCE_TYPES = [SITE, FORKLIFT, ROOM].freeze

      SYSTEM_RESOURCE_RULES = {
        SERVER => { description: 'Server', attributes: { ip_address: :string } },
        MODULE => { description: 'Module', computing_device: true, attributes: { ip_address: :string, sub_types: [CLM_ROBOT, QC_ROBOT, SCALE_ROBOT, FORKLIFT_ROBOT, PALLETIZING_ROBOT, BIN_TIPPING_ROBOT] } },
        MODULE_BUTTON => { description: 'Module button', computing_device: true, attributes: { ip_address: :string, sub_types: [ROBOT_BUTTON] } },
        PERIPHERAL => { description: 'Peripheral', peripheral: true, attributes: { ip_address: :string } }
      }.freeze

      PLANT_RESOURCE_RULES = {
        SITE => { description: 'Site',
                  allowed_children: [PACKHOUSE, ROOM],
                  icon: { file: 'globe', colour: CLR_H } },
        PACKHOUSE => { description: 'Packhouse',
                       allowed_children: [ROOM, LINE, CLM_ROBOT, SCALE_ROBOT, QC_ROBOT, PALLETIZING_BAY, SCALE, PRINTER, BIN_VERIFICATION_STATION, WEIGHING_STATION],
                       icon: { file: 'factory', colour: CLR_N } },
        ROOM => { description: 'Room',
                  allowed_children: [QC_ROBOT, SCALE_ROBOT, SCALE, PRINTER, WEIGHING_STATION],
                  icon: { file: 'home', colour: CLR_K } },
        LINE => { description: 'Line',
                  allowed_children: [DROP, DROP_STATION, DROP_TABLE, CLM_ROBOT, QC_ROBOT, PALLETIZING_BAY, BIN_TIPPING_STATION, SCALE, PRINTER, PRINT_STATION],
                  icon: { file: 'packline', colour: CLR_S } },
        DROP => { description: 'Drop',
                  allowed_children: [DROP_STATION, DROP_TABLE, CLM_ROBOT, SCALE_ROBOT, SCALE, PRINTER],
                  icon: { file: 'packing', colour: CLR_D } },
        DROP_STATION => { description: 'Drop station',
                          allowed_children: [DROP, CLM_ROBOT, SCALE_ROBOT, SCALE, PRINTER],
                          icon: { file: 'station', colour: CLR_R } },
        DROP_TABLE => { description: 'Drop table',
                        allowed_children: [CLM_ROBOT, SCALE_ROBOT, SCALE, PRINTER],
                        icon: { file: 'packing', colour: CLR_N } },
        ROBOT_BUTTON => { description: 'Robot button',
                          allowed_children: [],
                          icon: { file: 'circle-o', colour: CLR_O },
                          create_with_system_resource: 'MODULE_BUTTON',
                          sequence_without_zero_padding: true,  ## spec no zeros.... (default == 1)
                          code_prefix: '${CODE}-B' }, # prefixed by module name followed by....
        CLM_ROBOT => { description: 'CLM Robot',
                       allowed_children: [ROBOT_BUTTON],
                       icon: { file: 'server3', colour: CLR_E },
                       create_with_system_resource: 'MODULE',
                       code_prefix: 'CLM-' },
        QC_ROBOT => { description: 'QC Robot',
                      allowed_children: [],
                      icon: { file: 'server3', colour: CLR_L },
                      create_with_system_resource: 'MODULE',
                      code_prefix: 'QCM-' },
        SCALE_ROBOT => { description: 'Scale Robot',
                         allowed_children: [],
                         icon: { file: 'server3', colour: CLR_P },
                         create_with_system_resource: 'MODULE',
                         code_prefix: 'SCM-' },
        FORKLIFT_ROBOT => { description: 'Forklift Robot',
                            allowed_children: [],
                            icon: { file: 'server3', colour: CLR_F },
                            create_with_system_resource: 'MODULE',
                            code_prefix: 'FKM-' },
        PALLETIZING_ROBOT => { description: 'Palletizing Robot',
                               allowed_children: [],
                               icon: { file: 'server3', colour: CLR_T },
                               create_with_system_resource: 'MODULE',
                               code_prefix: 'PTM-' },
        BIN_TIPPING_ROBOT => { description: 'Bintipping Robot',
                               allowed_children: [],
                               icon: { file: 'server3', colour: CLR_Q },
                               create_with_system_resource: 'MODULE',
                               code_prefix: 'BTM-' },
        FORKLIFT => { description: 'Forklift',
                      allowed_children: [FORKLIFT_ROBOT],
                      icon: { file: 'forkishlift', colour: CLR_M } },
        PALLETIZING_BAY => { description: 'Palletizing Bay',
                             allowed_children: [PALLETIZING_ROBOT, SCALE, PRINTER],
                             icon: { file: 'cube', colour: CLR_G } },
        SCALE => { description: 'Scale',
                   allowed_children: [],
                   create_with_system_resource: PERIPHERAL,
                   icon: { file: 'balance-scale', colour: CLR_I },
                   non_editable_code: true,
                   code_prefix: 'SCL-' },
        PRINTER => { description: 'Printer',
                     allowed_children: [],
                     create_with_system_resource: PERIPHERAL,
                     icon: { file: 'printer', colour: CLR_A },
                     non_editable_code: true,
                     code_prefix: 'PRN-' },
        BIN_TIPPING_STATION => { description: 'Bin-tipping station',
                                 allowed_children: [BIN_TIPPING_ROBOT, SCALE],
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
                              allowed_children: [SCALE_ROBOT, SCALE, PRINTER],
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

      # FTP..
      # add module with robot, use prefix for mod only & check db for next value
      # What happens if XML config has srv-01:clm-01 and srv-02:clm-04 and clm-01 is renamed to clm-03 and clm-04 becomes clm-01 ?
      # MODULE could be CLM, SCM, QCM.. (get prefix from plant - "P:" or module_type..)

      def self.refresh_plant_resource_types # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        cnt = 0
        repo = BaseRepo.new
        PLANT_RESOURCE_RULES.each_key do |key|
          next if repo.exists?(:plant_resource_types, plant_resource_type_code: key)

          icon = PLANT_RESOURCE_RULES[key][:icon].nil? ? nil : PLANT_RESOURCE_RULES[key][:icon].values.join(',')

          repo.create(:plant_resource_types,
                      plant_resource_type_code: key,
                      icon: icon,
                      description: PLANT_RESOURCE_RULES[key][:description])
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

      def self.peripheral_type_codes
        PLANT_RESOURCE_RULES.select { |_, v| v[:create_with_system_resource] == PERIPHERAL }.keys
      end
    end
  end
end
