class AppClientSettingsLoader # rubocop:disable Metrics/ClassLength
  REPLACE_RULES = { # These should become client rules!
    IMPLEMENTATION_OWNER: { env_key: 'IMPLEMENTATION_OWNER',
                            required: true,
                            desc: 'The name of the implementation client.' },
    CARTON_VERIFICATION_REQUIRED: { env_key: 'CARTON_VERIFICATION_REQUIRED',
                                    boolean: true,
                                    desc: 'Determines if the system implementation requires carton_verification' },
    PROVIDE_PACK_TYPE_AT_VERIFICATION: { env_key: 'PROVIDE_PACK_TYPE_AT_VERIFICATION',
                                         boolean: true,
                                         desc: 'Provide pack type at carton verification' },
    # NB: When converting to client rule, note that this const is part of program_function menu rules in db/menu
    USE_CARTON_PALLETIZING: { env_key: 'USE_CARTON_PALLETIZING',
                              boolean: true,
                              desc: 'Use carton palletizing application. Default false' },
    AUTO_PRINT_PALLET_LABEL_ON_BAY: { env_key: 'AUTO_PRINT_PALLET_LABEL_ON_BAY',
                                      boolean: true,
                                      desc: 'Carton Palletizing - Print pallet labels on pallet complete only if true.' },
    ALLOW_OVERFULL_PALLETIZING: { env_key: 'ALLOW_OVERFULL_PALLETIZING', boolean: true,
                                  desc: 'Carton Palletizing - If FALSE auto complete pallet if pallets cartons_per_pallet is reached.' },
    ALLOW_OVERFULL_REWORKS_PALLETIZING: { env_key: 'ALLOW_OVERFULL_REWORKS_PALLETIZING',
                                          boolean: true,
                                          desc: 'Reworks Palletizing - If FALSE auto complete pallet if pallets cartons_per_pallet is reached in reworks.' },
    # ALLOW_CULTIVAR_GROUP_MIXING: { env_key: 'ALLOW_CULTIVAR_GROUP_MIXING',
    #                                boolean: true,
    #                                desc: 'Allow users to set allow_cultivar_group_mixing flag on production_runs' },
    DELIVERY_DEFAULT_FARM: { env_key: 'DEFAULT_FARM',
                             desc: 'Many pack houses will receive fruit from only one farm. System should therefore allow for a default value.' },
    DELIVERY_CAPTURE_INNER_BINS: { env_key: 'CAPTURE_INNER_BINS',
                                   boolean: true,
                                   desc: 'Applies when RMT Containers have inner containers eg. Lugs on trailers for grapes.' },
    DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION: { env_key: 'CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION',
                                                      boolean: true,
                                                      desc: 'In future, some packhouses may want to integrate a physical scale so that weights can be obtained directly from the scale.' },
    DELIVERY_CAPTURE_CONTAINER_MATERIAL: { env_key: 'CAPTURE_CONTAINER_MATERIAL',
                                           boolean: true,
                                           desc: 'Type of bin at delivery eg. Wood, Plastic (Required for empty bin control)' },
    DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER: { env_key: 'CAPTURE_CONTAINER_MATERIAL_OWNER',
                                                 boolean: true,
                                                 desc: 'Capture container material owner at delivery eg. Chep (Required for empty bin control)' },
    DELIVERY_CAPTURE_DAMAGED_BINS: { env_key: 'CAPTURE_DAMAGED_BINS',
                                     boolean: true,
                                     desc: 'Optional capture at delivery' },
    DELIVERY_CAPTURE_EMPTY_BINS: { env_key: 'CAPTURE_EMPTY_BINS',
                                   boolean: true,
                                   desc: 'Optional capture at delivery' },
    DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION: { env_key: 'CAPTURE_TRUCK_AT_FRUIT_RECEPTION',
                                                 boolean: true,
                                                 desc: 'Optional capture at delivery' },
    BULK_BIN_ASSET_NUMBER_ENTRY: { env_key: 'BULK_BIN_ASSET_NUMBER_ENTRY',
                                   boolean: true,
                                   desc: 'create the bin group as per usual, but allocate bin asset numbers from the user provided list inside text area' },
    ALLOW_AUTO_BIN_ASSET_NUMBER_ALLOCATION: { env_key: 'ALLOW_AUTO_BIN_ASSET_NUMBER_ALLOCATION',
                                              boolean: true,
                                              desc: 'Determines if bins asset_numbers are auto generated or scanned in.' },
    EDIT_BIN_RECEIVED_DATE: { env_key: 'EDIT_BIN_RECEIVED_DATE',
                              boolean: true,
                              desc: 'Allow a user to able to edit received_date_time' },
    BIN_SCANNING_BATCH_SIZE: { env_key: 'BIN_SCANNING_BATCH_SIZE',
                               default: 10,
                               desc: 'Can allow so many bins to be scanned at a time at bin reception' },
    # Regular expression(s) to validate bin asset numbers when present (in case they are typed in incorrectly)
    # If more than one format is required, separate with commas (no spaces).
    BIN_ASSET_REGEX: { env_key: 'BIN_ASSET_REGEX',
                       default: '.+',
                       desc: 'One or more regular expressions (delimited by commas) to validate the format of typed-in bin asset numbers.' },
    VAT_FACTOR: { env_key: 'VAT_FACTOR',
                  desc: 'To calculate vat amounts for the delivery cost invoice report' },
    PHC_LEVEL: { env_key: 'PHC_LEVEL',
                 required: true,
                 desc: 'Resource Level at which the PHC code is stored. Can be "LINE" or "PACKHOUSE".' },
    ALLOW_EXPORT_PALLETS_TO_BYPASS_INSPECTION: { env_key: 'ALLOW_EXPORT_PALLETS_TO_BYPASS_INSPECTION',
                                                 boolean: true,
                                                 desc: 'optional. Allow non LO pallets to be set to in_stock by users' },
    CALCULATE_PALLET_DECK_POSITIONS: { env_key: 'CALCULATE_PALLET_DECK_POSITIONS',
                                       boolean: true,
                                       desc: 'Works out deck position where pallet should go.' },
    PALLET_MIX_RULES_SCOPE: { env_key: 'PALLET_MIX_RULES_SCOPE',
                              array_split: ',',
                              desc: 'a list of scope values for pallet_mix_rules.' },
    DEFAULT_CARGO_TEMP_ON_ARRIVAL: { env_key: 'DEFAULT_CARGO_TEMP_ON_ARRIVAL',
                                     desc: 'The cargo temperature_code to default for containers on truck arrival.' },
    DEFAULT_FG_PACKAGING_TYPE: { env_key: 'DEFAULT_FG_PACKAGING_TYPE',
                                 default: 'CARTON',
                                 desc: 'Default fg packaging type pm_type_code for Product Setups. Habata will be BIN while Matrooz will be CARTON' },
    # REQUIRE_EXTENDED_PACKAGING: { env_key: 'REQUIRE_EXTENDED_PACKAGING',
    #                               boolean: true,
    #                               desc: 'If REQUIRE_EXTENDED_PACKAGING is true, packaging for product setup is extended. Default false' },
    REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION: { env_key: 'REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION',
                                                    boolean: true,
                                                    desc: 'optional. Show field if fruit sticker is required.' },
    COMBINE_CARTON_AND_PALLET_VERIFICATION: { env_key: 'COMBINE_CARTON_AND_PALLET_VERIFICATION',
                                              boolean: true, desc: 'optional. The system presents a screen prompting the user to scan either a pallet number or a carton number.' },
    CAPTURE_PALLET_WEIGHT_AT_VERIFICATION: { env_key: 'CAPTURE_PALLET_WEIGHT_AT_VERIFICATION', boolean: true,
                                             desc: 'optional. Fill in the gross weight at pallet verification,' },
    PALLET_IS_IN_STOCK_WHEN_VERIFIED: { env_key: 'PALLET_IS_IN_STOCK_WHEN_VERIFIED',
                                        boolean: true,
                                        desc: 'When a pallet is verified, take it into stock immediately. (Do not wait for an inspection)' },
    PRINT_PALLET_LABEL_AT_PALLET_VERIFICATION: { env_key: 'PRINT_PALLET_LABEL_AT_PALLET_VERIFICATION',
                                                 boolean: true,
                                                 desc: 'optional. The shows print label fields at pallet verification.' },
    DEFAULT_PACKING_METHOD: { env_key: 'DEFAULT_PACKING_METHOD',
                              default: 'NORMAL',
                              desc: 'Default packing method code for product resource allocations' },
    DEFAULT_FIRST_INTAKE_LOCATION: { env_key: 'DEFAULT_FIRST_INTAKE_LOCATION',
                                     desc: 'Default first intake location.' },
    CREATE_STOCK_AT_FIRST_INTAKE: { env_key: 'CREATE_STOCK_AT_FIRST_INTAKE',
                                    boolean: true,
                                    desc: 'Create stock at first intake.' },
    USE_MARKETING_PUC: { env_key: 'USE_MARKETING_PUC',
                         boolean: true,
                         desc: 'If USE_MARKETING_PUC is true, populate carton_labels and pallet_sequences marketing_puc_id and use marketing organization farm_puc to lookup registered_orchards (marketing_orchard_id). Default false' },
    GTINS_REQUIRED: { env_key: 'GTINS_REQUIRED',
                      boolean: true,
                      desc: 'If GTINS_REQUIRED is true, use masterfile code and/or variants to lookup a gtin_code. Default false' },
    LOCATION_TYPES_COLD_BAY_DECK: { env_key: 'LOCATION_TYPES_COLD_BAY_DECK',
                                    default: 'DECK',
                                    desc: 'The code for location types that serve as bays in cold storage. Default is "DECK"' },
    ADDENDUM_PLACE_OF_ISSUE: { env_key: 'ADDENDUM_PLACE_OF_ISSUE', default: 'CPT', validation_regex: /cpt|dbn|plz|mpm|oth/i, desc: 'Exporter ceritficate place of issue for addendum. Can be CPT, DBN. MPM, PLZ or OTH.' },
    BYPASS_QUALITY_TEST_LOAD_CHECK: { env_key: 'BYPASS_QUALITY_TEST_LOAD_CHECK', boolean: true, default: true, desc: 'optional. Bypasses Quality checks at Pallet Loading' },
    BYPASS_QUALITY_TEST_PRE_RUN_CHECK: { env_key: 'BYPASS_QUALITY_TEST_PRE_RUN_CHECK', boolean: true, default: true, desc: 'optional. Bypasses Quality checks before a run is started' },
    DEFAULT_EXPORTER: { env_key: 'DEFAULT_EXPORTER', desc: 'Default Exporter Party for new loads and inspections.' },
    DEFAULT_INSPECTION_BILLING: { env_key: 'DEFAULT_INSPECTION_BILLING', desc: 'Default Inspection Billing Party for new inspections.' },
    EDI_AUTO_CREATE_MF: { env_key: 'EDI_AUTO_CREATE_MF', boolean: true, desc: 'For EDI in, do we create missing masterfiles automatically?' },
    GOVT_INSPECTION_SIGNEE_CAPTION: { env_key: 'GOVT_INSPECTION_SIGNEE_CAPTION', default: 'Packhouse manager', desc: 'Inspection report - Signee caption - only needs to be set if it should not be "Packhouse manager"' },
    HIDE_INTAKE_TRIP_SHEET_ON_GOVT_INSPECTION_SHEET: { env_key: 'HIDE_INTAKE_TRIP_SHEET_ON_GOVT_INSPECTION_SHEET', boolean: true, desc: 'Determines if tripsheet can be created or not' },
    INCENTIVISED_LABELING: { env_key: 'INCENTIVISED_LABELING', boolean: true, desc: 'True if a worker must be logged-in to print a carton label.' },
    PS_APPLY_SUBSTITUTES: { env_key: 'PS_APPLY_SUBSTITUTES', boolean: true, desc: 'If true, include extra substitute columns in PS EDI out.' },
    ROBOT_DISPLAY_LINES: { env_key: 'ROBOT_DISPLAY_LINES', default: 0, format: :integer, desc: 'Do all robots on site have the same no of lines? If so, set to 4 or 5 as required.' },
    TEMP_TAIL_REQUIRED_TO_SHIP: { env_key: 'TEMP_TAIL_REQUIRED_TO_SHIP', boolean: true, desc: 'optional. Makes temp tail required on all loads' },
    USE_EXTENDED_PALLET_PICKLIST: { env_key: 'USE_EXTENDED_PALLET_PICKLIST', boolean: true, desc: 'Jasper report for picklist. If extended, use "dispatch_picklist", else use "picklist".' }
  }.freeze

  FIXED_RULES = {
    APP_CAPTION: { env_key: 'APP_CAPTION', desc: 'The application name' },
    LABEL_VARIABLE_SETS: { env_key: 'LABEL_VARIABLE_SETS',
                           array_split: ',',
                           desc: 'Variable sets available for designing labels' },
    QUEUE_NAME: { env_key: 'QUEUE_NAME',
                  default: 'default',
                  desc: 'The name of the job Que.' }
  }.freeze

  RULES = {
    CLIENT_CODE: { env_key: 'CLIENT_CODE',
                   required: true,
                   desc: 'Short, lowercase code to identify the implementation client. Used e.g. in defining per-client behaviour.' },
    URL_BASE: { env_key: 'URL_BASE',
                required: true,
                desc: 'Base URL for this website - in the format http://xxxx (where xxxx is an IP address or DNS name).' },
    URL_BASE_IP: { env_key: 'URL_BASE_IP',
                   required: true,
                   desc: 'Base URL IP address for this website - in the format http://999.999.999.999 (where 999.999.999.999 is an IP address).' },
    DEFAULT_PALLET_LABEL_NAME: { env_key: 'DEFAULT_PALLET_LABEL_NAME',
                                 desc: 'Default pallet label_name for Carton Palletizing.' },
    RMT_INTEGRATION_SERVER_URI: { env_key: 'RMT_INTEGRATION_SERVER_URI',
                                  desc: 'HTTP address of the RMT Integration Server in the format http://IP:3000.' },
    PRESORT1_STAGING_MSSQL_SERVER_INTERFACE: { env_key: 'PRESORT1_STAGING_MSSQL_SERVER_INTERFACE',
                                               desc: 'HTTP address of the MsSql Interface Server for presort plant 1 in the format http://IP:8080. Used in bin_staging and bin_tipped services.' },
    PRESORT2_STAGING_MSSQL_SERVER_INTERFACE: { env_key: 'PRESORT2_STAGING_MSSQL_SERVER_INTERFACE',
                                               desc: 'HTTP address of the MsSql Interface Server for presort plant 2 in the format http://IP:8086. Used in bin_staging and bin_tipped services.' },
    PRESORT1_PRODUCTION_MSSQL_SERVER_INTERFACE: { env_key: 'PRESORT1_PRODUCTION_MSSQL_SERVER_INTERFACE',
                                                  desc: 'HTTP address of the MsSql Interface Server for presort plant 1 in the format http://IP:8086. Used in bin_created service.' },
    PRESORT2_PRODUCTION_MSSQL_SERVER_INTERFACE: { env_key: 'PRESORT2_PRODUCTION_MSSQL_SERVER_INTERFACE',
                                                  desc: 'HTTP address of the MsSql Interface Server for presort plant 2 in the format http://IP:8086. Used in bin_created service.' },
    DEFAULT_RMT_CONTAINER_TYPE: { env_key: 'DEFAULT_RMT_CONTAINER_TYPE',
                                  default: 'BIN',
                                  desc: 'Default container type code for presort integration services' },
    GLN_OR_LINE_NUMBERS: { env_key: 'GLN_OR_LINE_NUMBERS',
                           required: true,
                           array_split: ',',
                           desc: 'A comma-separated list of GLN or line numbers. Must be composed of digits only' },
    EST_PALLETS_PACKED_PER_YEAR: { env_key: 'EST_PALLETS_PACKED_PER_YEAR',
                                   default: 25_000,
                                   format: :integer,
                                   desc: 'An estimate of the number of pallets packed in a year (season). Used to report the number of available pallet numbers per GLN.' },
    LABEL_SERVER_URI: { env_key: 'LABEL_SERVER_URI',
                        required: true,
                        desc: 'HTTP address of MesServer in the format http://IP:2080/ NOTE: the trailing "/" is required.' },
    SHARED_CONFIG_HOST_PORT: { env_key: 'SHARED_CONFIG_HOST_PORT',
                               required: true,
                               desc: 'IP address of shared_config in the format HOST:PORT' },
    LABEL_PUBLISH_NOTIFY_URLS: { env_key: 'LABEL_PUBLISH_NOTIFY_URLS',
                                 default: '',
                                 array_split: ',',
                                 desc: 'HTTP address of the publish notify urls separated by ",". e.g. http://localhost:9296/masterfiles/config/label_templates/published' },
    BATCH_PRINT_MAX_LABELS: { env_key: 'BATCH_PRINT_MAX_LABELS',
                              default: 20,
                              format: :integer,
                              desc: 'Maximum quantity of carton labels to print in a batch' },
    PREVIEW_PRINTER_TYPE: { env_key: 'PREVIEW_PRINTER_TYPE',
                            default: 'zebra',
                            desc: 'Which printer type is the default choice for label image previews' },
    # Label sizes. The arrays contain width then height.
    DEFAULT_LABEL_DIMENSION: { env_key: 'DEFAULT_LABEL_DIMENSION',
                               default: '84x64',
                               desc: 'User`s preferred label dimension in mm (width then height) e.g. 100x100' },
    LABEL_SIZES: { env_key: 'LABEL_SIZES',
                   label_sizes: true,
                   desc: 'Possible label sizes for designing in format "w,h;w,h;w,h...". e.g. 100,100;150,100;84,64' },
    LABEL_LOCATION_BARCODE: { env_key: 'LABEL_LOCATION_BARCODE',
                              default: 'NSPACK_LOCATION',
                              desc: 'Label name for Locations' },
    LABEL_BIN_BARCODE: { env_key: 'LABEL_BIN_BARCODE',
                         default: 'MAIN_BIN',
                         desc: 'Label name for Bins' },
    LABEL_CARTON_VERIFICATION: { env_key: 'LABEL_CARTON_VERIFICATION',
                                 default: 'BIN_VERIFICATION',
                                 desc: 'Label name for Cartons' },
    LABEL_PACKPOINT_BARCODE: { env_key: 'LABEL_PACKPOINT_BARCODE',
                               default: 'PACKPOINT',
                               desc: 'Label name for Packpoint barcode' },
    LABEL_PERSONNEL_BARCODE: { env_key: 'LABEL_PERSONNEL_BARCODE',
                               default: 'PERSONNEL',
                               desc: 'Label name for Personnel number barcode' },
    ERROR_MAIL_RECIPIENTS: { env_key: 'ERROR_MAIL_RECIPIENTS',
                             required: true,
                             desc: 'Comma-separated list of recipients of exception emails.' },
    LEGACY_SYSTEM_ERROR_RECIPIENTS: { env_key: 'LEGACY_SYSTEM_ERROR_RECIPIENTS',
                                      desc: 'Comma-separated list of recipients for kr integration error emails.' },
    ERROR_MAIL_PREFIX: { env_key: 'ERROR_MAIL_PREFIX',
                         required: true,
                         desc: 'Prefix to be placed in subject of emails sent from exceptions.' },
    SYSTEM_MAIL_SENDER: { env_key: 'SYSTEM_MAIL_SENDER',
                          required: true,
                          desc: 'Email address for "FROM" address in the format NAME<email>' },
    EMAIL_REQUIRES_REPLY_TO: { env_key: 'EMAIL_REQUIRES_REPLY_TO',
                               boolean: true,
                               desc: 'Set to Y if user cannot send email directly. i.e. FROM must be system email, and REPLY-TO will be set to user email.' },
    MAX_PASSENGER_INSTANCES: { env_key: 'MAX_PASSENGER_INSTANCES',
                               default: 30,
                               format: :integer,
                               desc: 'Number of passenger instance as set in /etc/nginx/conf.d/mod-http-passenger.conf' },
    PASSENGER_USAGE_LEVEL: { env_key: 'PASSENGER_USAGE_LEVEL',
                             default: 'INFO',
                             desc: 'Lowest state for passenger usage to send emails. Can be INFO, BUSY or HIGH.' },
    EDI_NETWORK_ADDRESS: { env_key: 'EDI_NETWORK_ADDRESS', default: '999', desc: 'Network address for sending EDI documents' },
    EDI_RECEIVE_DIR: { env_key: 'EDI_RECEIVE_DIR', desc: 'The directory to which received EDI files are copied (by the EdiReceiveCheck script) to be processed by the receive EDI job.' },
    SOLAS_VERIFICATION_METHOD: { env_key: 'SOLAS_VERIFICATION_METHOD', desc: 'SOLAS verification method (1 or 2). required for some EDI out documents' },
    SAMSA_ACCREDITATION: { env_key: 'SAMSA_ACCREDITATION', desc: 'For sending EDI documents' },
    JASPER_REPORTS_PATH: { env_key: 'JASPER_REPORTS_PATH', desc: "Full path to client's Jasper report definitions" },
    JRUBY_JASPER_HOST_PORT: { env_key: 'JRUBY_JASPER_HOST_PORT', desc: 'IP address of jruby jasper reporting engine in the format HOST:PORT' },
    TITAN_ENVIRONMENT: { env_key: 'TITAN_ENVIRONMENT', default: 'UAT', desc: "Titan API environment for government inspections. { UAT: 'uat', STAGING: 'staging', PRODUCTION: '' }" },
    TITAN_INSPECTION_API_USER_ID: { env_key: 'TITAN_INSPECTION_API_USER_ID', desc: 'Titan API_UserId for government inspections.' },
    TITAN_INSPECTION_API_SECRET: { env_key: 'TITAN_INSPECTION_API_SECRET', desc: 'Titan API_Secret for government inspections.' },
    TITAN_ADDENDUM_API_USER_ID: { env_key: 'TITAN_ADDENDUM_API_USER_ID', desc: 'Titan API_UserId for government addenda.' },
    TITAN_ADDENDUM_API_SECRET: { env_key: 'TITAN_ADDENDUM_API_SECRET', desc: 'Titan API_Secret for government addenda.' },
    PHYT_CLEAN_API_USERNAME: { env_key: 'PHYT_CLEAN_API_USERNAME', desc: 'optional. PhytClean API User Name' },
    PHYT_CLEAN_API_PASSWORD: { env_key: 'PHYT_CLEAN_API_PASSWORD', desc: 'optional. PhytClean API Password' },
    PHYT_CLEAN_SEASON_ID: { env_key: 'PHYT_CLEAN_SEASON_ID', desc: 'optional. PhytClean Standard Data season id' },
    PHYT_CLEAN_OPEN_TIMEOUT: { env_key: 'PHYT_CLEAN_OPEN_TIMEOUT', default: 5, format: :integer, desc: 'PHYTCLEAN: Time in seconds to wait for API connection' },
    PHYT_CLEAN_READ_TIMEOUT: { env_key: 'PHYT_CLEAN_READ_TIMEOUT', default: 10, format: :integer, desc: 'PHYTCLEAN: Time in seconds to wait for API response' },
    PHYT_CLEAN_SEASON_END_DATE: { env_key: 'PHYT_CLEAN_SEASON_END_DATE', desc: 'End date of phytclean season. Set it to stop running Phytclean updates after this date. Optional or YYYY-MM-DD format' },
    E_CERT_ENVIRONMENT: { env_key: 'E_CERT_ENVIRONMENT', default: 'QA', desc: 'optional. eCert API Environment' },
    E_CERT_API_CLIENT_ID: { env_key: 'E_CERT_API_CLIENT_ID', desc: 'optional. eCert API  Client ID' },
    E_CERT_API_CLIENT_SECRET: { env_key: 'E_CERT_API_CLIENT_SECRET', desc: 'optional. eCert API Secret' },
    E_CERT_BUSINESS_ID: { env_key: 'E_CERT_BUSINESS_ID', desc: 'optional. eCert API Business ID' },
    E_CERT_BUSINESS_NAME: { env_key: 'E_CERT_BUSINESS_NAME', desc: 'optional. eCert API Business Name' },
    E_CERT_INDUSTRY: { env_key: 'E_CERT_INDUSTRY', desc: 'optional. eCert API Industry' },
    E_CERT_OPEN_TIMEOUT: { env_key: 'E_CERT_OPEN_TIMEOUT', default: 5, format: :integer, desc: 'E-CERT: Time in seconds to wait for API connection' },
    E_CERT_READ_TIMEOUT: { env_key: 'E_CERT_READ_TIMEOUT', default: 10, format: :integer, desc: 'E-CERT: Time in seconds to wait for API response' }
  }.freeze

  DEVELOPER_RULES = {
    VERBOSE_ROBOT_FEEDBACK_LOGGING: { env_key: 'VERBOSE_ROBOT_FEEDBACK_LOGGING',
                                      boolean: true,
                                      desc: 'Log full XML robot feedback response messages.' }
  }.freeze

  # Any value that starts with y, Y, t or T is considered true.
  # All else is false.
  def self.check_true(val)
    val.match?(/^[TtYy]/)
  end

  # Take an environment variable and interpret it
  # as a boolean.
  #
  # If required is true, the variable MUST have a value.
  # If default_true is true, the value will be set to true if the variable has no value.
  def self.make_boolean(key, required: false, default_true: false)
    val = if required
            ENV.fetch(key)
          else
            ENV.fetch(key, default_true ? 't' : 'f')
          end
    check_true(val)
  end

  # Helper to create hash of label sizes from a 2D array.
  def self.make_label_size_hash(str)
    array = if str.nil? || str.empty?
              [
                [84,   64], [97,   78], [100,  70], [100,  84], [100, 100], [130, 100], [145,  50], [150, 100]
              ]
            else
              str.split(';').map { |s| s.split(',') }
            end
    Hash[array.map { |w, h| ["#{w}x#{h}", { 'width': w, 'height': h }] }].freeze
  end

  def self.client_settings_with_desc # rubocop:disable Metrics/AbcSize
    out = []
    FIXED_RULES.each do |name, rule|
      out << { key: name, desc: rule[:desc], env_val: get_env_val(rule[:env_key]), const_val: get_rule(name, rule).last }
    end
    out << { key: '<strong>TRUE CLIENT SETTINGS</strong>', desc: '', env_val: '', const_val: '<em><strong>Stored in .env.local</strong></em>' }
    RULES.each do |name, rule|
      out << { key: name, desc: rule[:desc], env_val: get_env_val(rule[:env_key]), const_val: get_rule(name, rule).last }
    end
    out << { key: '<strong>TO BE REPLACED WITH CLIENT RULES</strong>', desc: '', env_val: '', const_val: '<em><strong>Stored in .env.local - to become client rules</strong></em>' }
    REPLACE_RULES.each do |name, rule|
      out << { key: name, desc: rule[:desc], env_val: get_env_val(rule[:env_key]), const_val: get_rule(name, rule).last }
    end
    out << { key: '<strong>DEVELOPMENT SETTINGS</strong>', desc: '', env_val: '', const_val: '<em><strong>Rules for development</strong></em>' }
    DEVELOPER_RULES.each do |name, rule|
      out << { key: name, desc: rule[:desc], env_val: get_env_val(rule[:env_key]), const_val: get_rule(name, rule).last }
    end

    out
  end

  def self.client_settings
    out = []
    FIXED_RULES.each do |name, rule|
      out << get_rule(name, rule)
    end
    RULES.each do |name, rule|
      out << get_rule(name, rule)
    end
    REPLACE_RULES.each do |name, rule|
      out << get_rule(name, rule)
    end
    DEVELOPER_RULES.each do |name, rule|
      out << get_rule(name, rule)
    end

    out
  end

  def self.get_env_val(name)
    ENV[name]
  end

  def self.get_rule(name, rule) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    val = if rule[:boolean]
            if rule[:default]
              make_boolean(rule[:env_key], default_true: true)
            else
              make_boolean(rule[:env_key])
            end
          elsif rule[:default_env_var]
            thisval = ENV[rule[:env_key]]
            thisval || ENV[rule[:default_env_var]]
          elsif rule[:label_sizes]
            make_label_size_hash(ENV[rule[:env_key]])
          elsif rule[:format]
            ENV.fetch(rule[:env_key], rule[:default]).to_i # Currently only an integer format...
          elsif rule[:array_split]
            ENV.fetch(rule[:env_key], rule[:default]).to_s.strip.split(rule[:array_split])
          else
            ENV.fetch(rule[:env_key], rule[:default])
          end
    raise %(ENV variable "#{rule[:env_key]} must be provided") if rule[:required] && (val.nil? || val.empty?)
    raise %(ENV variable "#{rule[:env_key]} value #{val} does not match #{rule[:validation_regex]}") if rule[:validation_regex] && !val.match?(rule[:validation_regex])

    [name, val]
  end

  def self.new_env_var_line(rule)
    evar = ENV[rule[:env_key]]
    comment = evar.nil? ? '# ' : ''
    val = evar || rule[:default]
    if rule[:required]
      "#{rule[:env_key]}=#{val} (REQUIRED) [#{rule[:desc]}]"
    elsif rule[:default] && !comment.empty?
      "#{comment}#{rule[:env_key]}=#{val} (this is default, only change if not this value) [#{rule[:desc]}]"
    else
      "#{comment}#{rule[:env_key]}=#{val} (OPTIONAL) [#{rule[:desc]}]"
    end
  end

  def self.env_var_line(name, rule) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    evar = ENV[rule[:env_key]]
    comment = evar.nil? ? '# ' : ''
    vv = get_rule(name, rule)
    val = if evar.nil?
            case vv.last
            when TrueClass
              'y'
            when FalseClass
              'n'
            else
              vv.last
            end
          else
            evar
          end
    if rule[:required]
      "#{name}=#{val} (REQUIRED) [#{rule[:desc]}]"
    elsif rule[:default] && !comment.empty?
      "#{comment}#{name}=#{val} (this is default, only change if not this value) [#{rule[:desc]}]"
    else
      "#{comment}#{name}=#{val} (OPTIONAL) [#{rule[:desc]}]"
    end
  end

  def self.env_var_file
    out = ['']
    RULES.sort.each do |name, rule|
      out << env_var_line(name, rule)
    end
    out << "\n# THESE SETTINGS WILL BE REPLACED BY CLIENT RULES...\n"
    REPLACE_RULES.sort.each do |name, rule|
      out << env_var_line(name, rule)
    end
    out << "\n# THESE SETTINGS ARE TYPICALLY ONLY USED FOR DEBUGGING/DEVELOPER USAGE...\n"
    DEVELOPER_RULES.sort.each do |name, rule|
      out << env_var_line(name, rule)
    end
    out.join("\n")
  end

  def self.new_env_var_file(required_values_only: false)
    out = ['']
    add_rules(RULES, out, required_values_only)
    out << "\n# THESE SETTINGS WILL BE REPLACED BY CLIENT RULES...\n"
    add_rules(REPLACE_RULES, out, required_values_only)
    unless required_values_only
      out << "\n# THESE SETTINGS ARE TYPICALLY ONLY USED FOR DEBUGGING/DEVELOPER USAGE...\n"
      add_rules(DEVELOPER_RULES, out, required_values_only)
    end
    out.join("\n")
  end

  def self.add_rules(rules, out, required_values_only)
    rules.sort.each do |_, rule|
      next if required_values_only && !rule[:required]

      out << new_env_var_line(rule)
    end
  end
end
