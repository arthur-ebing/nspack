# frozen_string_literal: true

# List of all required environment variables with descriptions.
class EnvVarRules # rubocop:disable Metrics/ClassLength
  OPTIONAL = [
    { DONOTLOGSQL: 'Dev mode: do not log SQL calls' },
    { LOGSQLTOFILE: 'Dev mode: separate SQL calls out of logs and write to file "log/sql.log"' },
    { LOGFULLMESSERVERCALLS: 'Dev mode: Log full payload of HTTP calls to MesServer. Only do this if debugging.' },
    { RUN_FOR_RMD: 'Dev mode: Force the server to act as if it is being called from a Registered Mobile Device' },
    { NO_ERR_HANDLE: 'Dev mode: Do not use the error handling built into the framework. Can be useful to debug without mail sending in the output.' },
    { DEFAULT_FARM: 'Many pack houses will receive fruit from only one farm. System should therefore allow for a default value.' },
    { CAPTURE_INNER_BINS: 'qty_inner_bins only applicable to certain clients.' },
    { CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION: 'In future, Some packhouse may want to integrate a physical scale so that weights can be obtained directly from the scale.' },
    { CAPTURE_CONTAINER_MATERIAL: 'rmt_container_material_type not applicable to all clients.' },
    { CAPTURE_CONTAINER_MATERIAL_OWNER: 'rmt_container_material_owner not applicable to all clients.' },
    { USE_DELIVERY_DESTINATION: 'not applicable to many clients.' },
    { CAPTURE_DAMAGED_BINS: 'not applicable to many clients.' },
    { CAPTURE_EMPTY_BINS: 'not applicable to many clients.' },
    { CAPTURE_TRUCK_AT_FRUIT_RECEPTION: 'optional, not applicable to many clients.' },
    { USE_PERMANENT_RMT_BIN_BARCODES: 'Capture deliveries with permanently barcoded bins.' },
    { REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION: 'optional. Show field if fruit sticker is required.' },
    { CAPTURE_PALLET_WEIGHT_AT_VERIFICATION: 'optional. Fill in the gross weight at pallet verification,' },
    { COMBINE_CARTON_AND_PALLET_VERIFICATION: 'optional. The system presents a screen prompting the user to scan either a pallet number or a carton number.' },
    { EMAIL_REQUIRES_REPLY_TO: 'Set to Y if user cannot send email directly. i.e. FROM must be system email, and REPLY-TO will be set to user email.' },
    { DEFAULT_MARKETING_ORG: 'Default marketing organization party_role_name for Product Setups' },
    { DEFAULT_FG_PACKAGING_TYPE: 'Default fg packaging type pm_type_code for Product Setups. Habata will be BIN while Matrooz will be CARTON' },
    { REQUIRE_PACKAGING_BOM: 'Require packaging bom for Product Setups. Display PM Subtype and PM BOM if true' },
    { DEFAULT_LABEL_DIMENSION: 'User`s preferred label dimension in mm (width then height) e.g. 100x100' },
    { LABEL_SIZES: 'Possible label sizes for designing in format "w,h;w,h;w,h...". e.g. 100,100;100,150;84,64' },
    { CARTON_EQUALS_PALLET: 'Create pallets and pallet_sequences from carton. Default false' },
    { CARTON_VERIFICATION_REQUIRED: 'Determines if the system implementation requires carton_verification' },
    { PALLET_IS_IN_STOCK_WHEN_VERIFIED: 'When a pallet is verified, take it into stock immediately. (Do not wait for an inspection)' },
    { PROVIDE_PACK_TYPE_AT_VERIFICATION: 'Provide pack type at carton verification' },
    { LABEL_LOCATION_BARCODE: 'Label name for Locations' },
    { LABEL_BIN_BARCODE: 'Label name for Bins' },
    { LABEL_CARTON_VERIFICATION: 'Label name for Cartons' },
    { VGM_REQUIRED: 'Sets if verified gross mass as required for RMD load_containers.' },
    { DEFAULT_DEPOT: 'Default Depot for new dispatch loads.' },
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
    { PS_APPLY_SUBSTITUTES: 'If true, include extra substitute columns in PS EDI out.' }
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
    { DEFAULT_RMT_CONTAINER_TYPE: 'This should be set behind the scenes, since it will almost always be the same thing, e.g. ‘bins’, for a given packhouse.' },
    { CHRUBY_STRING: 'The version of chruby used in development. Used in Rake tasks.' },
    { PHC_LEVEL: 'Resource Level at which the PHC code is stored. Can be "LINE" or "PACKHOUSE".' }
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
    { URL_BASE: 'Base URL for this website - in the format http://xxxx' }
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
    array.map { |var| "#{var.keys.first.to_s.ljust(25)} : #{var.values.first}" }.join("\n")
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
