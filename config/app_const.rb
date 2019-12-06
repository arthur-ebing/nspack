# frozen_string_literal: true

# A class for defining global constants in a central place.
class AppConst # rubocop:disable Metrics/ClassLength
  def self.development?
    ENV['RACK_ENV'] == 'development'
  end

  # Any value that starts with y, Y, t or T is considered true.
  # All else is false.
  def self.check_true(val)
    val.match?(/^[TtYy]/)
  end

  # Take an environment variable and interpret it
  # as a boolean.
  def self.make_boolean(key, required: false)
    val = if required
            ENV.fetch(key)
          else
            ENV.fetch(key, 'f')
          end
    check_true(val)
  end

  # Helper to create hash of label sizes from a 2D array.
  def self.make_label_size_hash(array)
    Hash[array.map { |w, h| ["#{w}x#{h}", { 'width': w, 'height': h }] }].freeze
  end

  # Client-specific code
  CLIENT_CODE = ENV.fetch('CLIENT_CODE')
  IMPLEMENTATION_OWNER = ENV.fetch('IMPLEMENTATION_OWNER')

  # labeling cached setup data path
  LABELING_CACHED_DATA_FILEPATH = File.expand_path('../tmp/run_cache', __dir__)

  # carton verification
  CARTON_EQUALS_PALLET = make_boolean('CARTON_EQUALS_PALLET')
  CARTON_VERIFICATION_REQUIRED = make_boolean('CARTON_VERIFICATION_REQUIRED')
  PROVIDE_PACK_TYPE_AT_VERIFICATION = make_boolean('PROVIDE_PACK_TYPE_AT_VERIFICATION')

  # General
  DEFAULT_KEY = 'DEFAULT'

  # Deliveries
  DELIVERY_DEFAULT_FARM = ENV['DEFAULT_FARM']
  DELIVERY_CAPTURE_INNER_BINS = make_boolean('CAPTURE_INNER_BINS')
  DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION = make_boolean('CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION')
  DELIVERY_DEFAULT_RMT_CONTAINER_TYPE = ENV.fetch('DEFAULT_RMT_CONTAINER_TYPE')
  DELIVERY_CAPTURE_CONTAINER_MATERIAL = make_boolean('CAPTURE_CONTAINER_MATERIAL')
  DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER = make_boolean('CAPTURE_CONTAINER_MATERIAL_OWNER')
  DELIVERY_CAPTURE_DAMAGED_BINS = make_boolean('CAPTURE_DAMAGED_BINS')
  DELIVERY_USE_DELIVERY_DESTINATION = make_boolean('USE_DELIVERY_DESTINATION')
  DELIVERY_CAPTURE_EMPTY_BINS = make_boolean('CAPTURE_EMPTY_BINS')
  DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION = make_boolean('CAPTURE_TRUCK_AT_FRUIT_RECEPTION')
  USE_PERMANENT_RMT_BIN_BARCODES = make_boolean('USE_PERMANENT_RMT_BIN_BARCODES')

  # Resources
  PHC_LEVEL = ENV.fetch('PHC_LEVEL')
  GLN_OR_LINE_NUMBERS = ENV.fetch('GLN_OR_LINE_NUMBERS').split(',')

  # Constants for pallet statuses:
  PALLETIZED_NEW_PALLET = 'PALLETIZED_NEW_PALLET'
  RW_PALLET_SINGLE_EDIT = 'RW_PALLET_SINGLE_EDIT'
  RW_PALLET_BATCH_EDIT = 'RW_PALLET_BATCH_EDIT'
  PALLETIZED_SEQUENCE_ADDED = 'PALLETIZED_SEQUENCE_ADDED'
  PALLETIZED_SEQUENCE_REPLACED = 'PALLETIZED_SEQUENCE_REPLACED'
  PALLETIZED_SEQUENCE_UPDATED = 'PALLETIZED_SEQUENCE_UPDATED'

  # Constants for PM Types
  PM_TYPE_FRUIT_STICKER = 'fruit_sticker'

  # Pallet verification
  REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION = make_boolean('REQUIRE_FRUIT_STICKER_AT_PALLET_VERIFICATION')
  COMBINE_CARTON_AND_PALLET_VERIFICATION = make_boolean('COMBINE_CARTON_AND_PALLET_VERIFICATION')
  CAPTURE_PALLET_NETT_WEIGHT_AT_VERIFICATION = make_boolean('CAPTURE_PALLET_NETT_WEIGHT_AT_VERIFICATION')
  PALLET_IS_IN_STOCK_WHEN_VERIFIED = make_boolean('PALLET_IS_IN_STOCK_WHEN_VERIFIED')

  # Constants for pallets exit_ref
  PALLET_EXIT_REF_SCRAPPED = 'SCRAPPED'
  PALLET_EXIT_REF_REMOVED = 'REMOVED'

  # Constants for roles:
  ROLE_IMPLEMENTATION_OWNER = 'IMPLEMENTATION_OWNER'
  ROLE_CUSTOMER = 'CUSTOMER'
  ROLE_SUPPLIER = 'SUPPLIER'
  # ROLE_TRANSPORTER = 'TRANSPORTER'
  ROLE_MARKETER = 'MARKETER'
  ROLE_FARM_OWNER = 'FARM_OWNER'
  ROLE_SHIPPING_LINE = 'SHIPPING_LINE'
  ROLE_SHIPPER = 'SHIPPER'
  ROLE_FINAL_RECEIVER = 'FINAL_RECEIVER'
  ROLE_EXPORTER = 'EXPORTER'
  ROLE_BILLING_CLIENT = 'BILLING_CLIENT'
  ROLE_CONSIGNEE = 'CONSIGNEE'
  ROLE_HAULIER = 'HAULIER'
  ROLE_INSPECTOR = 'INSPECTOR'
  ROLE_INSPECTION_BILLING = 'INSPECTION_BILLING'

  # Default roles
  DEFAULT_EXPORTER = ENV['DEFAULT_EXPORTER']
  DEFAULT_INSPECTION_BILLING = ENV['DEFAULT_INSPECTION_BILLING']

  # Target Market Type: 'PACKED'
  PACKED_TM_GROUP = 'PACKED'

  # Product Setup default marketing organization
  DEFAULT_MARKETING_ORG = ENV['DEFAULT_MARKETING_ORG']

  # Defaults for Packaging
  DEFAULT_FG_PACKAGING_TYPE = ENV['DEFAULT_FG_PACKAGING_TYPE']
  REQUIRE_PACKAGING_BOM = make_boolean('REQUIRE_PACKAGING_BOM')

  # Default UOM TYPE
  UOM_TYPE = 'INVENTORY'

  # Constants for Reworks run types:
  RUN_TYPE_SINGLE_PALLET_EDIT = 'SINGLE PALLET EDIT'
  RUN_TYPE_BATCH_PALLET_EDIT = 'BATCH PALLET EDIT'
  RUN_TYPE_SCRAP_PALLET = 'SCRAP PALLET'
  RUN_TYPE_UNSCRAP_PALLET = 'UNSCRAP PALLET'
  RUN_TYPE_REPACK = 'REPACK PALLET'
  RUN_TYPE_BUILDUP = 'BUILDUP'
  RUN_TYPE_TIP_BINS = 'TIP BINS'

  # Constants for Reworks run actions:
  REWORKS_ACTION_SINGLE_EDIT = 'SINGLE EDIT'
  REWORKS_ACTION_BATCH_EDIT = 'BATCH EDIT'
  REWORKS_ACTION_CLONE = 'CLONE'
  REWORKS_ACTION_REMOVE = 'REMOVE'
  REWORKS_ACTION_EDIT_CARTON_QUANTITY = 'EDIT CARTON QUANTITY'
  REWORKS_ACTION_CHANGE_PRODUCTION_RUN = 'CHANGE PRODUCTION RUN'
  REWORKS_ACTION_CHANGE_FARM_DETAILS = 'CHANGE FARM DETAILS'
  REWORKS_ACTION_SET_GROSS_WEIGHT = 'SET GROSS WEIGHT'
  REWORKS_ACTION_UPDATE_PALLET_DETAILS = 'UPDATE PALLET DETAILS'

  # Routes that do not require login:
  BYPASS_LOGIN_ROUTES = [
    '/masterfiles/config/label_templates/published',
    '/messcada/.*'
  ].freeze

  # Menu
  FUNCTIONAL_AREA_RMD = 'RMD'

  # Logging
  FIELDS_TO_EXCLUDE_FROM_DIFF = %w[label_json png_image].freeze

  # MesServer
  LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')
  POST_FORM_BOUNDARY = 'AaB03x'

  # Labels
  SHARED_CONFIG_HOST_PORT = ENV.fetch('SHARED_CONFIG_HOST_PORT')
  LABEL_VARIABLE_SETS = ENV.fetch('LABEL_VARIABLE_SETS').strip.split(',')
  LABEL_PUBLISH_NOTIFY_URLS = ENV.fetch('LABEL_PUBLISH_NOTIFY_URLS', '').split(',')
  BATCH_PRINT_MAX_LABELS = ENV.fetch('BATCH_PRINT_MAX_LABELS', 20).to_i

  # Label sizes. The arrays contain width then height.
  DEFAULT_LABEL_DIMENSION = ENV.fetch('DEFAULT_LABEL_DIMENSION', '84x64')
  LABEL_SIZES = if ENV['LABEL_SIZES']
                  AppConst.make_label_size_hash(ENV['LABEL_SIZES'].split(';').map { |s| s.split(',') })
                else
                  AppConst.make_label_size_hash(
                    [
                      [84,   64], [84,  100], [97,   78], [78,   97], [77,  130], [100,  70],
                      [100,  84], [100, 100], [105, 250], [130, 100], [145,  50], [100, 150]
                    ]
                  )
                end

  # Label names for barcode printing:
  LABEL_LOCATION_BARCODE = ENV.fetch('LABEL_LOCATION_BARCODE', 'NSPACK_LOCATION')
  LABEL_BIN_BARCODE = ENV.fetch('LABEL_BIN_BARCODE', 'MAIN_BIN')
  LABEL_CARTON_VERIFICATION = ENV.fetch('LABEL_CARTON_VERIFICATION', 'BIN_VERIFICATION')

  # Printers
  PRINTER_USE_INDUSTRIAL = 'INDUSTRIAL'
  PRINTER_USE_OFFICE = 'OFFICE'

  PRINT_APP_LOCATION = 'Location'
  PRINT_APP_BIN = 'Bin'
  PRINT_APP_CARTON = 'Carton'
  PRINT_APP_PALLET = 'Pallet'

  PRINTER_APPLICATIONS = [
    PRINT_APP_LOCATION,
    PRINT_APP_BIN,
    PRINT_APP_CARTON,
    PRINT_APP_PALLET
  ].freeze

  # These will need to be configured per installation...
  BARCODE_PRINT_RULES = {
    location: { format: 'LC%d', fields: [:id] },
    # sku: { format: 'SK%d', fields: [:sku_number] },
    # delivery: { format: 'DN%d', fields: [:delivery_number] },
    bin: { format: 'BN%d', fields: [:id] }
  }.freeze

  BARCODE_SCAN_RULES = [
    { regex: '^LC(\\d+)$', type: 'location', field: 'id' },
    { regex: '^(\\D\\D\\D)$', type: 'location', field: 'location_short_code' },
    # { regex: '^(\\D\\D\\D)$', type: 'dummy', field: 'code' },
    # { regex: '^SK(\\d+)', type: 'sku', field: 'sku_number' },
    # { regex: '^DN(\\d+)', type: 'delivery', field: 'delivery_number' },
    { regex: '^BN(\\d+)', type: 'bin', field: 'id' },
    { regex: '^(\\d+)', type: 'pallet_number', field: 'pallet_number' },
    { regex: '^(\\d+)', type: 'carton_label_id', field: 'id' },
    { regex: '^SK(\\d+)', type: 'bin_asset', field: 'bin_asset_number' }, # asset no should change to string and this should not require SK.
    { regex: '^(\\d+)', type: 'load', field: 'id' }
  ].freeze

  # Per scan type, per field, set attributes for displaying a lookup value below a scan field.
  # The key matches a key in BARCODE_PRINT_RULES. (e.g. :location)
  # The hash for that key is keyed by the value of the BARCODE_SCAN_RULES :field. (e.g. :id)
  # The rules for that field are: the table to read, the field to match the scanned value and the field to display in the form.
  # If a join is required, specify join: table_name and on: Hash of field on source table: field on target table.
  BARCODE_LOOKUP_RULES = {
    location: {
      id: { table: :locations, field: :id, show_field: :location_long_code },
      location_short_code: { table: :locations, field: :location_short_code, show_field: :location_long_code }
    },
    sku: {
      sku_number: { table: :mr_skus,
                    field: :sku_number,
                    show_field: :product_variant_code,
                    join: :material_resource_product_variants,
                    on: { id: :mr_product_variant_id } }
    }
  }.freeze

  # Que
  QUEUE_NAME = ENV.fetch('QUEUE_NAME', 'default')

  # Mail
  ERROR_MAIL_RECIPIENTS = ENV.fetch('ERROR_MAIL_RECIPIENTS')
  ERROR_MAIL_PREFIX = ENV.fetch('ERROR_MAIL_PREFIX')
  SYSTEM_MAIL_SENDER = ENV.fetch('SYSTEM_MAIL_SENDER')
  EMAIL_REQUIRES_REPLY_TO = make_boolean('EMAIL_REQUIRES_REPLY_TO')
  EMAIL_GROUP_LABEL_APPROVERS = 'label_approvers'
  EMAIL_GROUP_LABEL_PUBLISHERS = 'label_publishers'
  USER_EMAIL_GROUPS = [EMAIL_GROUP_LABEL_APPROVERS, EMAIL_GROUP_LABEL_PUBLISHERS].freeze

  # Business Processes
  # PROCESS_DELIVERIES = 'DELIVERIES'
  # PROCESS_VEHICLE_JOBS = 'VEHICLE JOBS'
  # PROCESS_ADHOC_TRANSACTIONS = 'ADHOC TRANSACTIONS'
  # PROCESS_BULK_STOCK_ADJUSTMENTS = 'BULK STOCK ADJUSTMENTS'

  # Locations: Location Types
  LOCATION_TYPES_RECEIVING_BAY = 'RECEIVING BAY'

  # Depots: Depot Code
  DEFAULT_DEPOT = ENV['DEFAULT_DEPOT']

  # Load_containers:
  VGM_REQUIRED = make_boolean(ENV['VGM_REQUIRED'])

  # Constants for port types:
  PORT_TYPE_POL = 'POL'
  PORT_TYPE_POD = 'POD'

  # ERP_PURCHASE_INVOICE_URI = ENV.fetch('ERP_PURCHASE_INVOICE_URI', 'default')

  BIG_ZERO = BigDecimal('0')
  # The maximum size of an integer in PostgreSQL
  MAX_DB_INT = 2_147_483_647

  # Titan: Govt Inspections
  TITAN_ENVIRONMENT = { UAT: 'uatapigateway', STAGING: 'stagingapigateway', PRODUCTION: 'apigateway' }[ENV['TITAN_ENVIRONMENT'].to_sym]
  TITAN_API_USER_ID = ENV['TITAN_API_USER_ID']
  TITAN_API_SECRET = ENV['TITAN_API_SECRET']
end
