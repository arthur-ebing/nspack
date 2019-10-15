# frozen_string_literal: true

module Crossbeams
  module Config
    # Store rules for Resource types like how to build resource trees and associations.
    class ResourceDefinitions # rubocop:disable Metrics/ClassLength
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
                  icon: { file: 'globe', colour: '#90c6b0' } },
        PACKHOUSE => { description: 'Packhouse',
                       allowed_children: [ROOM, LINE, CLM_ROBOT, SCALE_ROBOT, QC_ROBOT, PALLETIZING_BAY, SCALE, PRINTER, BIN_VERIFICATION_STATION],
                       icon: { file: 'factory', colour: '#c791bc' } },
        ROOM => { description: 'Room',
                  allowed_children: [QC_ROBOT, SCALE_ROBOT, SCALE, PRINTER],
                  icon: { file: 'home', colour: '#a8364c' } },
        LINE => { description: 'Line',
                  allowed_children: [DROP, DROP_STATION, DROP_TABLE, CLM_ROBOT, QC_ROBOT, PALLETIZING_BAY, BIN_TIPPING_STATION, SCALE, PRINTER, PRINT_STATION],
                  icon: { file: 'packline', colour: '#a8364c' } },
        DROP => { description: 'Drop',
                  allowed_children: [DROP_STATION, DROP_TABLE, CLM_ROBOT, SCALE_ROBOT, SCALE, PRINTER],
                  icon: { file: 'packing', colour: '#36a864' } },
        DROP_STATION => { description: 'Drop station',
                          allowed_children: [DROP, CLM_ROBOT, SCALE_ROBOT, SCALE, PRINTER],
                          icon: { file: 'station', colour: '#e0ce7f' } },
        DROP_TABLE => { description: 'Drop table',
                        allowed_children: [CLM_ROBOT, SCALE_ROBOT, SCALE, PRINTER],
                        icon: { file: 'packing', colour: '#c791bc' } },
        ROBOT_BUTTON => { description: 'Robot button',
                          allowed_children: [],
                          icon: { file: 'circle-o', colour: '#c9665f' },
                          create_with_system_resource: 'MODULE_BUTTON',
                          sequence_without_zero_padding: true,  ## spec no zeros.... (default == 1)
                          code_prefix: '${CODE}-B' }, # prefixed by module name followed by....
        CLM_ROBOT => { description: 'CLM Robot',
                       allowed_children: [ROBOT_BUTTON],
                       icon: { file: 'server3', colour: '#5F98CA' },
                       create_with_system_resource: 'MODULE',
                       code_prefix: 'CLM-' },
        QC_ROBOT => { description: 'QC Robot',
                      allowed_children: [],
                      icon: { file: 'server3', colour: '#c65fc9' },
                      create_with_system_resource: 'MODULE',
                      code_prefix: 'QCM-' },
        SCALE_ROBOT => { description: 'Scale Robot',
                         allowed_children: [],
                         icon: { file: 'server3', colour: '#c9915f' },
                         create_with_system_resource: 'MODULE',
                         code_prefix: 'SCM-' },
        FORKLIFT_ROBOT => { description: 'Forklift Robot',
                            allowed_children: [],
                            icon: { file: 'server3', colour: '#62c95f' },
                            create_with_system_resource: 'MODULE',
                            code_prefix: 'FKM-' },
        PALLETIZING_ROBOT => { description: 'Palletizing Robot',
                               allowed_children: [],
                               icon: { file: 'server3', colour: '#c9665f' },
                               create_with_system_resource: 'MODULE',
                               code_prefix: 'PTM-' },
        BIN_TIPPING_ROBOT => { description: 'Bintipping Robot',
                               allowed_children: [],
                               icon: { file: 'server3', colour: '#c9bb5f' },
                               create_with_system_resource: 'MODULE',
                               code_prefix: 'BTM-' },
        FORKLIFT => { description: 'Forklift',
                      allowed_children: [FORKLIFT_ROBOT],
                      icon: { file: 'forkishlift', colour: '#c79191' } },
        PALLETIZING_BAY => { description: 'Palletizing Bay',
                             allowed_children: [PALLETIZING_ROBOT, SCALE, PRINTER],
                             icon: { file: 'cube', colour: '#80b8e0' } },
        SCALE => { description: 'Scale',
                   allowed_children: [],
                   create_with_system_resource: PERIPHERAL,
                   icon: { file: 'balance-scale', colour: '#9580e0' },
                   non_editable_code: true,
                   code_prefix: 'SCL-' },
        PRINTER => { description: 'Printer',
                     allowed_children: [],
                     create_with_system_resource: PERIPHERAL,
                     icon: { file: 'printer', colour: '#234722' },
                     non_editable_code: true,
                     code_prefix: 'PRN-' },
        BIN_TIPPING_STATION => { description: 'Bin-tipping station',
                                 allowed_children: [BIN_TIPPING_ROBOT, SCALE],
                                 icon: { file: 'cog', colour: '#9580e0' } },
        BIN_VERIFICATION_STATION => { description: 'Bin-verification station',
                                      allowed_children: [BIN_VERIFICATION_ROBOT, PRINTER],
                                      icon: { file: 'tag', colour: '#326699' } },
        BIN_VERIFICATION_ROBOT => { description: 'Bin verification Robot',
                                    allowed_children: [ROBOT_BUTTON],
                                    icon: { file: 'server3', colour: '#329932' },
                                    create_with_system_resource: 'MODULE',
                                    code_prefix: 'BVM-' },
        PRINT_STATION => { description: 'Print station',
                           allowed_children: [PRINT_STATION_ROBOT, PRINTER],
                           icon: { file: 'square-o', colour: '#993299' } },
        PRINT_STATION_ROBOT => { description: 'Print station Robot',
                                 allowed_children: [],
                                 icon: { file: 'server3', colour: '#326699' },
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

      def self.can_have_children?(plant_resource_type_code)
        !PLANT_RESOURCE_RULES[plant_resource_type_code][:allowed_children].empty?
      end

      def self.peripheral_type_codes
        PLANT_RESOURCE_RULES.select { |_, v| v[:create_with_system_resource] == PERIPHERAL }.keys
      end
    end
  end
end
