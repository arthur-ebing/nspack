# frozen_string_literal: true

# A class for defining global constants in a central place.
class AppConst
  # Client-specific code
  CLIENT_CODE = ENV.fetch('CLIENT_CODE')
  IMPLEMENTATION_OWNER = ENV.fetch('IMPLEMENTATION_OWNER')

  DELIVERY_DEFAULT_FARM = ENV['DEFAULT_FARM']
  DELIVERY_CAPTURE_INNER_BINS = ENV['CAPTURE_INNER_BINS']
  DELIVERY_CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION = ENV['CAPTURE_BIN_WEIGHT_AT_FRUIT_RECEPTION']
  DELIVERY_DEFAULT_RMT_CONTAINER_TYPE = ENV.fetch('DEFAULT_RMT_CONTAINER_TYPE')
  DELIVERY_CAPTURE_CONTAINER_MATERIAL = ENV['CAPTURE_CONTAINER_MATERIAL']
  DELIVERY_CAPTURE_CONTAINER_MATERIAL_OWNER = ENV['CAPTURE_CONTAINER_MATERIAL_OWNER']
  DELIVERY_CAPTURE_DAMAGED_BINS = ENV['CAPTURE_DAMAGED_BINS']
  DELIVERY_USE_DELIVERY_DESTINATION = ENV['USE_DELIVERY_DESTINATION']
  DELIVERY_CAPTURE_EMPTY_BINS = ENV['CAPTURE_EMPTY_BINS']
  DELIVERY_CAPTURE_TRUCK_AT_FRUIT_RECEPTION = ENV['CAPTURE_TRUCK_AT_FRUIT_RECEPTION']
  SCAN_RMT_BIN_ASSET_NUMBERS = ENV['SCAN_RMT_BIN_ASSET_NUMBERS']

  # Constants for roles:
  ROLE_IMPLEMENTATION_OWNER = 'IMPLEMENTATION_OWNER'
  # ROLE_CUSTOMER = 'CUSTOMER'
  # ROLE_SUPPLIER = 'SUPPLIER'
  # ROLE_TRANSPORTER = 'TRANSPORTER'

  # Routes that do not require login:
  BYPASS_LOGIN_ROUTES = [].freeze

  # Menu
  FUNCTIONAL_AREA_RMD = 'RMD'

  # Logging
  FIELDS_TO_EXCLUDE_FROM_DIFF = %w[label_json png_image].freeze

  # MesServer
  LABEL_SERVER_URI = ENV.fetch('LABEL_SERVER_URI')
  POST_FORM_BOUNDARY = 'AaB03x'

  # Labels
  SHARED_CONFIG_HOST_PORT = ENV.fetch('SHARED_CONFIG_HOST_PORT')
  # LABEL_LOCATION_BARCODE = 'KR_PM_LOCATION' # From ENV? / Big config gem?
  # LABEL_SKU_BARCODE = 'KR_PM_SKU' # From ENV? / Big config gem?

  # Printers
  PRINTER_USE_INDUSTRIAL = 'INDUSTRIAL'
  PRINTER_USE_OFFICE = 'OFFICE'

  # PRINT_APP_LOCATION = 'Location'
  # PRINT_APP_MR_SKU_BARCODE = 'Material Resource SKU Barcode'

  PRINTER_APPLICATIONS = [
    # PRINT_APP_LOCATION,
    # PRINT_APP_MR_SKU_BARCODE
  ].freeze

  # These will need to be configured per installation...
  BARCODE_PRINT_RULES = {
    # location: { format: 'LC%d', fields: [:id] },
    # sku: { format: 'SK%d', fields: [:sku_number] },
    # delivery: { format: 'DN%d', fields: [:delivery_number] },
    # stock_adjustment: { format: 'SA%d', fields: [:stock_adjustment_number] }
  }.freeze

  BARCODE_SCAN_RULES = [
    # { regex: '^LC(\\d+)$', type: 'location', field: 'id' },
    # { regex: '^(\\D\\D\\D)$', type: 'location', field: 'location_short_code' },
    # { regex: '^(\\D\\D\\D)$', type: 'dummy', field: 'code' },
    # { regex: '^SK(\\d+)', type: 'sku', field: 'sku_number' },
    # { regex: '^DN(\\d+)', type: 'delivery', field: 'delivery_number' },
    # { regex: '^SA(\\d+)', type: 'stock_adjustment', field: 'stock_adjustment_number' }
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
  EMAIL_REQUIRES_REPLY_TO = ENV.fetch('EMAIL_REQUIRES_REPLY_TO', 'N') == 'Y'
  USER_EMAIL_GROUPS = [].freeze

  # Business Processes
  # PROCESS_DELIVERIES = 'DELIVERIES'
  # PROCESS_VEHICLE_JOBS = 'VEHICLE JOBS'
  # PROCESS_ADHOC_TRANSACTIONS = 'ADHOC TRANSACTIONS'
  # PROCESS_BULK_STOCK_ADJUSTMENTS = 'BULK STOCK ADJUSTMENTS'

  # Locations: Location Types
  # LOCATION_TYPES_RECEIVING_BAY = 'RECEIVING BAY'

  # ERP_PURCHASE_INVOICE_URI = ENV.fetch('ERP_PURCHASE_INVOICE_URI', 'default')

  BIG_ZERO = BigDecimal('0')
end
