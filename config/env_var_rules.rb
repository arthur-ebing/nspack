# frozen_string_literal: true

# List of all required environment variables with descriptions.
class EnvVarRules # rubocop:disable Metrics/ClassLength
  OPTIONAL = [
    { DONOTLOGSQL: 'Dev mode: do not log SQL calls' },
    { LOGSQLTOFILE: 'Dev mode: separate SQL calls out of logs and write to file "log/sql.log"' },
    { LOGFULLMESSERVERCALLS: 'Dev mode: Log full payload of HTTP calls to MesServer. Only do this if debugging.' },
    { VERBOSE_ROBOT_FEEDBACK_LOGGING: 'Log full XML robot feedback response messages.' },
    { RUN_FOR_RMD: 'Dev mode: Force the server to act as if it is being called from a Registered Mobile Device' },
    { NO_ERR_HANDLE: 'Dev mode: Do not use the error handling built into the framework. Can be useful to debug without mail sending in the output.' },
    { DEFAULT_FARM: 'Many pack houses will receive fruit from only one farm. System should therefore allow for a default value.' },
    { CAPTURE_INNER_BINS: 'Applies when RMT Containers have inner containers eg. Lugs on trailers for grapes.' },
    { CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION: 'In future, some packhouses may want to integrate a physical scale so that weights can be obtained directly from the scale.' },
    { CAPTURE_CONTAINER_MATERIAL: 'Type of bin at delivery eg. Wood, Plastic (Required for empty bin control)' },
    { CAPTURE_CONTAINER_MATERIAL_OWNER: 'Capture container material owner at delivery eg. Chep (Required for empty bin control)' },
    { USE_DELIVERY_DESTINATION: 'Intended destination for a delivery of rmt_fruit eg. degreening or PH1' },
    { CAPTURE_DAMAGED_BINS: 'Optional capture at delivery' },
    { HIDE_INTAKE_TRIP_SHEET_ON_GOVT_INSPECTION_SHEET: 'Determines if tripsheet can be created or not' },
    { CAPTURE_EMPTY_BINS: 'Optional capture at delivery' },
    { CAPTURE_TRUCK_AT_FRUIT_RECEPTION: 'Optional capture at delivery' },
    { PALLET_MIX_RULES_SCOPE: 'a list of scope values for pallet_mix_rules.' },
    { USE_PERMANENT_RMT_BIN_BARCODES: 'Capture deliveries with permanently barcoded bins.' },
    { BULK_BIN_ASSET_NUMBER_ENTRY: 'create the bin group as per usual, but allocate bin asset numbers from the user provided list inside text area' },
    { CALCULATE_PALLET_DECK_POSITIONS: 'Works out deck position where pallet should go.' },
    { ALLOW_AUTO_BIN_ASSET_NUMBER_ALLOCATION: 'Determines if bins asset_numbers are auto generated or scanned in.' },
    # { INTEGRATE_WITH_EXTERNAL_RMT_SYSTEM: 'Checks if integration with an external system is required.' },
    { RMT_INTEGRATION_SERVER_URI: 'HTTP address of the RMT Integration Server in the format http://IP:3000.' },
    { BIN_SCANNING_BATCH_SIZE: 'Can allow so many bins to be scanned at a time at bin reception' },
    { EDIT_BIN_RECEIVED_DATE: 'Allow a user to able to edit received_date_time' },
    { REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION: 'optional. Show field if fruit sticker is required.' },
    { CAPTURE_PALLET_WEIGHT_AT_VERIFICATION: 'optional. Fill in the gross weight at pallet verification,' },
    { PALLET_WEIGHT_REQUIRED_FOR_INSPECTION: 'optional. Bool to set if weight is required' },
    { COMBINE_CARTON_AND_PALLET_VERIFICATION: 'optional. The system presents a screen prompting the user to scan either a pallet number or a carton number.' },
    { PRINT_PALLET_LABEL_AT_PALLET_VERIFICATION: 'optional. The shows print label fields at pallet verification.' },
    { EMAIL_REQUIRES_REPLY_TO: 'Set to Y if user cannot send email directly. i.e. FROM must be system email, and REPLY-TO will be set to user email.' },
    { DEFAULT_FG_PACKAGING_TYPE: 'Default fg packaging type pm_type_code for Product Setups. Habata will be BIN while Matrooz will be CARTON' },
    { REQUIRE_PACKAGING_BOM: 'Require packaging bom for Product Setups. Display PKG Subtype and PKG BOM if true' },
    { DEFAULT_LABEL_DIMENSION: 'User`s preferred label dimension in mm (width then height) e.g. 100x100' },
    { LABEL_SIZES: 'Possible label sizes for designing in format "w,h;w,h;w,h...". e.g. 100,100;100,150;84,64' },
    { CARTON_EQUALS_PALLET: 'Create pallets and pallet_sequences from carton. Default false' },
    { CARTON_VERIFICATION_REQUIRED: 'Determines if the system implementation requires carton_verification' },
    { PALLET_IS_IN_STOCK_WHEN_VERIFIED: 'When a pallet is verified, take it into stock immediately. (Do not wait for an inspection)' },
    { PROVIDE_PACK_TYPE_AT_VERIFICATION: 'Provide pack type at carton verification' },
    { LABEL_LOCATION_BARCODE: 'Label name for Locations' },
    { LABEL_BIN_BARCODE: 'Label name for Bins' },
    { LABEL_CARTON_VERIFICATION: 'Label name for Cartons' },
    { LABEL_PACKPOINT_BARCODE: 'Label name for Packpoint barcode' },
    { LABEL_PERSONNEL_BARCODE: 'Label name for Personnel number barcode' },
    # { VGM_REQUIRED: 'Sets if verified gross mass as required for RMD load_containers.' },
    { DEFAULT_DEPOT: 'Default Depot for new dispatch loads.' },
    { FROM_DEPOT: 'Sending Depot for PO out EDIs. Defaults to the value of DEFAULT_DEPOT.' },
    { DEFAULT_EXPORTER: 'Default Exporter Party for new loads and inspections.' },
    { DEFAULT_INSPECTION_BILLING: 'Default Inspection Billing Party for new inspections.' },
    { TITAN_ENVIRONMENT: "Titan API environment for government inspections. { UAT: 'uat', STAGING: 'staging', PRODUCTION: '' }" },
    { TITAN_API_USER_ID: 'Titan API_UserId for government inspections.' },
    { TITAN_API_SECRET: 'Titan API_Secret for government inspections.' },
    { ADDENDUM_PLACE_OF_ISSUE: 'Exporter ceritficate place of issue for addendum. Can be CPT, DBN. MPM, PLZ or OTH.' },
    { SOLAS_VERIFICATION_METHOD: 'SOLAS verification method (1 or 2). required for some EDI out documents' },
    { SAMSA_ACCREDITATION: 'For sending EDI documents' },
    { CLM_BUTTON_CAPTION_FORMAT: 'A format for captions to display on label printer robot buttons. See AppConst for more.' },
    { DEFAULT_CARGO_TEMP_ON_ARRIVAL: 'The cargo temperature_code to default for containers on truck arrival.' },
    { BASE_PACK_EQUALS_STD_PACK: 'If true, creating a std pack will automatically create a basic pack.' },
    { RPT_INDUSTRY: 'Industry specific reporting folder' },
    { INCENTIVISED_LABELING: 'True if a worker must be logged-in to print a carton label.' },
    { PS_APPLY_SUBSTITUTES: 'If true, include extra substitute columns in PS EDI out.' },
    { BIN_ASSET_REGEX: 'One or more regular expressions (delimited by commas) to validate the format of typed-in bin asset numbers.' },
    { DEFAULT_DELIVERY_LOCATION: 'The long code of the location to serve as the default for all deliveries. If not set, the location id will be blank, but bin moves will not work.' },
    { DEFAULT_FIRST_INTAKE_LOCATION: 'Default first intake location.' },
    { CREATE_STOCK_AT_FIRST_INTAKE: 'Create stock at first intake.' },
    { LOCATION_TYPES_COLD_BAY_DECK: 'The code for location types that serve as bays in cold storage. Default is "DECK"' },
    { GOVT_INSPECTION_SIGNEE_CAPTION: 'Inspection report - Signee caption - only needs to be set if it should not be "Packhouse manager"' },
    { DEFAULT_PACKING_METHOD: 'Default packing method code for product resource allocations' },
    { E_CERT_ENVIRONMENT: 'optional. eCert API Environment' },
    { E_CERT_API_CLIENT_ID: 'optional. eCert API  Client ID' },
    { E_CERT_API_CLIENT_SECRET: 'optional. eCert API Secret' },
    { E_CERT_BUSINESS_ID: 'optional. eCert API Business ID' },
    { E_CERT_BUSINESS_NAME: 'optional. eCert API Business Name' },
    { E_CERT_INDUSTRY: 'optional. eCert API Industry' },
    { PHYT_CLEAN_API_USERNAME: 'optional. PhytClean API User Name' },
    { PHYT_CLEAN_API_PASSWORD: 'optional. PhytClean API Password' },
    { PHYT_CLEAN_SEASON_ID: 'optional. PhytClean Standard Data season id' },
    { BYPASS_QUALITY_TEST_LOAD_CHECK: 'optional. Bypasses Quality checks at Pallet Loading' },
    { BYPASS_QUALITY_TEST_PRE_RUN_CHECK: 'optional. Bypasses Quality checks before a run is started' },
    { MAX_BINS_ON_LOAD: 'optional. Sets maximum bins allowed on load' },
    { MAX_PALLETS_ON_LOAD: 'optional. Sets maximum pallets allowed on load' },
    { ALLOW_CULTIVAR_GROUP_MIXING: 'Allow users to set allow_cultivar_group_mixing flag on production_runs' },
    { TEMP_TAIL_REQUIRED_TO_SHIP: 'optional. Makes temp tail required on all loads' },
    { VAT_FACTOR: 'To calculate vat amounts for the delivery cost invoice report' },
    { USE_CARTON_PALLETIZING: 'Use carton palletizing application. Default false' },
    { DEFAULT_PALLET_LABEL_NAME: 'Default pallet label_name for Carton Palletizing.' },
    { AUTO_PRINT_PALLET_LABEL_ON_BAY: 'Carton Palletizing - Print pallet labels on pallet complete only if true.' },
    { ALLOW_OVERFULL_PALLETIZING: 'Carton Palletizing - If FALSE auto complete pallet if pallets cartons_per_pallet is reached.' },
    { MAX_PASSENGER_INSTANCES: 'Number of passenger instance as set in /etc/nginx/conf.d/mod-http-passenger.conf' },
    { ALLOW_OVERFULL_REWORKS_PALLETIZING: 'Reworks Palletizing - If FALSE auto complete pallet if pallets cartons_per_pallet is reached in reworks.' },
    { ALLOW_EXPORT_PALLETS_TO_BYPASS_INSPECTION: 'optional. Allow non LO pallets to be set to in_stock by users' },
    { USE_LABEL_ID_ON_BIN_LABEL: 'If CARTON_EQUALS_PALLET is true, use carton_label_id instead of pallet_number to lookup carton_labels existence if USE_LABEL_ID_ON_BIN_LABEL is set to true. Default false' },
    { REQUIRE_EXTENDED_PACKAGING: 'If REQUIRE_EXTENDED_PACKAGING is true, packaging for product setup is extended. Default false' },
    { EST_PALLETS_PACKED_PER_YEAR: 'An estimate of the number of pallets packed in a year (season). Used to report the number of available pallet numbers per GLN.' },
    { NO_RUN_ALLOCATION: 'Product setups are not allocated to plant resources during run setup.' },
    { USE_MARKETING_PUC: 'If USE_MARKETING_PUC is true, populate carton_labels and pallet_sequences marketing_puc_id and use marketing organization farm_puc to lookup registered_orchards (marketing_orchard_id). Default false' },
    { GTINS_REQUIRED: 'If GTINS_REQUIRED is true, use masterfile code and/or variants to lookup a gtin_code. Default false' }
  ].freeze

  NO_OVERRIDE = [
    { RACK_ENV: 'This is set to "development" in the .env file and set to "production" by deployment settings.' },
    { APP_CAPTION: 'The application name to display in web pages.' },
    { DATABASE_NAME: 'The name of the database. This is mostly used to derive the test database name.' },
    { QUEUE_NAME: 'The name of the job Que.' }
  ].freeze

  CAN_OVERRIDE = [
    { DATABASE_URL: 'Database connection string in the format "postgres://USER:PASSS@HOST:PORT/DATABASE_NAME".' },
    { IMPLEMENTATION_OWNER: 'The name of the implementation client.' },
    { SHARED_CONFIG_HOST_PORT: 'IP address of shared_config in the format HOST:PORT' },
    { JRUBY_JASPER_HOST_PORT: 'IP address of jruby jasper reporting engine in the format HOST:PORT' },
    { DEFAULT_RMT_CONTAINER_TYPE: 'This should be set behind the scenes, since it will almost always be the same thing, e.g. ‘bins’, for a given packhouse.' },
    { CHRUBY_STRING: 'The version of chruby used in development. Used in Rake tasks.' },
    { PHC_LEVEL: 'Resource Level at which the PHC code is stored. Can be "LINE" or "PACKHOUSE".' },
    { PREVIEW_PRINTER_TYPE: 'Which printer type is the default choice for label image previews' }
  ].freeze

  MUST_OVERRIDE = [
    { LABEL_SERVER_URI: 'HTTP address of MesServer in the format http://IP:2080/ NOTE: the trailing "/" is required.' },
    { LABEL_PUBLISH_NOTIFY_URLS: 'HTTP address of the publish notify urls separated by ",". e.g. http://localhost:9296/masterfiles/config/label_templates/published' },
    { JASPER_REPORTING_ENGINE_PATH: 'Full path to dir containing JasperReportPrinter.jar' },
    { JASPER_REPORTS_PATH: "Full path to client's Jasper report definitions." },
    { SYSTEM_MAIL_SENDER: 'Email address for "FROM" address in the format NAME<email>' },
    { ERROR_MAIL_PREFIX: 'Prefix to be placed in subject of emails sent from exceptions.' },
    { ERROR_MAIL_RECIPIENTS: 'Comma-separated list of recipients of exception emails.' },
    { CLIENT_CODE: 'Short, lowercase code to identify the implementation client. Used e.g. in defining per-client behaviour.' },
    { GLN_OR_LINE_NUMBERS: 'A comma-separated list of GLN or line numbers. Must be composed of digits only' },
    { INSTALL_LOCATION: 'A maximum 7-character name for the location - required by EDI transformers' },
    { IN_TRANSIT_LOCATION: 'Long location code for pallets after shipped ' },
    { EDI_NETWORK_ADDRESS: 'Network address for sending EDI documents' },
    { URL_BASE: 'Base URL for this website - in the format http://xxxx (where xxxx is an IP address or DNS name).' },
    { URL_BASE_IP: 'Base URL IP address for this website - in the format http://999.999.999.999 (where 999.999.999.999 is an IP address).' }
  ].freeze

  def print
    puts <<~STR
      -----------------------------
      --- ENVIRONMENT VARIABLES ---
      -----------------------------
      - Certain environment variables are fixed in the .env file.
      - Some of them can be overridden in the .env.local file. These are effectively the client settings.
      - Others are just available to set temporarily when running in development.

      No need to change these variable settings:
      ==========================================
      #{format(NO_OVERRIDE)}

      These variable settings can be changed in .env.local:
      =====================================================
      #{format(CAN_OVERRIDE)}

      These variable settings MUST be changed in .env.local:
      ======================================================
      #{format(MUST_OVERRIDE)}

      These variable settings can be set on the fly in development mode:
      e.g. "NO_ERR_HANDLE=y rackup"
      ==================================================================
      #{format(OPTIONAL)}
    STR
  end

  def list_keys # rubocop:disable Metrics/AbcSize
    (NO_OVERRIDE.map { |a| a.keys.first } + CAN_OVERRIDE.map { |a| a.keys.first } + MUST_OVERRIDE.map { |a| a.keys.first } + OPTIONAL.map { |a| a.keys.first }).sort.join("\n")
  end

  def client_settings # rubocop:disable Metrics/AbcSize
    one_hash = {}
    NO_OVERRIDE.each { |h| one_hash[h.keys.first] = h.values.first }
    CAN_OVERRIDE.each { |h| one_hash[h.keys.first] = h.values.first }
    MUST_OVERRIDE.each { |h| one_hash[h.keys.first] = h.values.first }
    OPTIONAL.each { |h| one_hash[h.keys.first] = h.values.first }
    keys = (NO_OVERRIDE.map { |a| a.keys.first } + CAN_OVERRIDE.map { |a| a.keys.first } + MUST_OVERRIDE.map { |a| a.keys.first } + OPTIONAL.map { |a| a.keys.first }).sort
    ar = []
    keys.each do |key|
      hs = { key: key, env_val: (ENV[key.to_s] || '').gsub(',', ', ') } # rubocop:disable Lint/Env
      description = one_hash[key]
      hs[:key] = %(<span class="fw5 near-black">#{key}</span><br><span class="f6">#{description}</span>)
      hs[:const_val] = AppConst.const_defined?(key) ? AppConst.const_get(key).to_s.gsub(',', ', ') : nil
      ar << hs
    end
    ar << { key: '<strong>APP CONST</strong>', env_val: '<strong>OTHER CONSTANTS</strong>', const_val: '<strong>(Value is hard-coded or might come from ENV VAR)</strong>' }
    consts = AppConst.constants.sort
    (consts - keys).each do |key|
      hs = { key: key, env_val: (ENV[key.to_s] || '').gsub(',', ', ') } # rubocop:disable Lint/Env
      description = ''
      hs[:key] = %(<span class="fw5 near-black">#{key}</span><br><span class="f6">#{description}</span>)
      hs[:const_val] = AppConst.const_defined?(key) ? AppConst.const_get(key).to_s.gsub(',', ', ') : nil
      ar << hs
    end
    ar
  end

  def root_path
    @root_path ||= File.expand_path('..', __dir__)
  end

  def env_keys
    envs = File.readlines(File.join(root_path, '.env'))
    ar = []
    envs.each { |e| ar << e.split('=').first unless e.strip.start_with?('#') }
    ar
  end

  def local_keys
    envs = File.readlines(File.join(root_path, '.env.local'))
    ar = []
    envs.each { |e| ar << e.split('=').first unless e.strip.start_with?('#') }
    ar
  end

  def existing
    @existing ||= (env_keys + local_keys).uniq
  end

  def format(array)
    array.map { |var| "#{var.keys.first.to_s.ljust(48)} : #{var.values.first}" }.join("\n")
  end

  def validate
    validation_check(NO_OVERRIDE, 'Must be present in ".env"')
    validation_check(CAN_OVERRIDE, 'Must be present in ".env" or ".env.local"')
    validation_check(MUST_OVERRIDE, 'Must be present in ".env.local"')
    puts "\nValidation complete"
  end

  def missing_check(array)
    msg = []
    array.each do |env|
      msg << "- Missing: #{env.keys.first} (#{env.values.first})" unless existing.include?(env.keys.first.to_s)
    end
    msg
  end

  def validation_check(array, desc)
    msg = missing_check(array)
    puts msg.empty? ? "#{desc} - OK" : desc
    puts msg.join("\n") unless msg.empty?
  end

  def add_missing_to_local
    to_add = []
    MUST_OVERRIDE.each do |env|
      k = env.keys.first.to_s
      v = env.values.first
      unless local_keys.include?(k)
        to_add << "# #{k}=#{v}\n"
        puts "Adding: #{k} (#{v})"
      end
    end

    update_local_file(to_add) unless to_add.empty?
  end

  def update_local_file(to_add)
    File.open(File.join(root_path, '.env.local'), 'a') { |f| to_add.each { |a| f << a } }
    puts "\nUpdated \".env.local\" - please modify (current contents are shown here):\n\n"
    puts File.read(File.join(root_path, '.env.local'))
  end
end
