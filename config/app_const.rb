# frozen_string_literal: true

# A class for defining global constants in a central place.
class AppConst # rubocop:disable Metrics/ClassLength
  require_relative 'client_settings_loader'

  def self.development?
    ENV['RACK_ENV'] == 'development'
  end

  def self.mssql_server_interface(plant)
    name = "PRESORT#{plant[-1]}_MSSQL_SERVER_INTERFACE"
    raise Crossbeams::FrameworkError, "Plant #{plant} is not a valid name for mapping to a SQL server interface (#{name})." unless const_defined?(name)

    val = const_get(name)
    raise Crossbeams::FrameworkError, "Client setting \"#{name}\" has not been set." if val.nil?

    val
  end

  def self.test?
    ENV['RACK_ENV'] == 'test'
  end

  # Client-specific code
  CLIENT_SET = {
    'hb' => 'Habata (Badlands)',
    'hl' => 'Habata (Loftus)',
    'um' => 'Unifrutti Matroozefontein',
    'ud' => 'Unifrutti Dunbrody',
    'sr' => 'Sitrusrand Kirkwood',
    'sr2' => 'Sitrusrand Addo',
    'kr' => 'Kromco'
  }.freeze

  # Load the client settings from ENV:
  AppClientSettingsLoader.client_settings.each do |set|
    AppConst.const_set(set.first, set.last)
  end
  raise 'CLIENT_CODE must be lowercase.' unless CLIENT_CODE == CLIENT_CODE.downcase
  raise "Unknown CLIENT_CODE - #{CLIENT_CODE}" unless CLIENT_SET.keys.include?(CLIENT_CODE)

  SHOW_DB_NAME = ENV.fetch('DATABASE_URL').rpartition('@').last

  # A struct that can be used to alter the client code while tests are running.
  # All the CB_ classes will use this value as the client_code, which allows
  # for testing different values for a setting.
  # Be sure to set client_code = boot_client_code at the end of tests for consistency.
  TEST_SETTINGS = OpenStruct.new(client_code: CLIENT_CODE, boot_client_code: CLIENT_CODE)

  # Load client-specific rules:
  # NB: these must start with CR_ and the class must start with "Client".
  CR_PROD = Crossbeams::ClientProductionRules.new(CLIENT_CODE)
  CR_FG = Crossbeams::ClientFgRules.new(CLIENT_CODE)
  CR_EDI = Crossbeams::ClientEdiRules.new(CLIENT_CODE)
  CR_MF = Crossbeams::ClientMfRules.new(CLIENT_CODE)
  CR_RMT = Crossbeams::ClientRmtRules.new(CLIENT_CODE)

  # Log for errors experienced by robot calls (Keep history: 10 files of up to 1Mb each):
  ROBOT_LOG = Logger.new('log/robot.log', 10, 1_024_000)

  # Logs requests, responses and errors for bin staging execution services (Keep history: 10 files of up to 1Mb each)
  BIN_STAGING_LOG_FILE = 'log/bin_staging_execution.log'
  BIN_STAGING_LOG = Logger.new(BIN_STAGING_LOG_FILE, 10, 1_024_000)

  # Logs requests, responses and errors for tipped bin service (Keep history: 10 files of up to 1Mb each)
  PRESORT_BIN_TIPPED_LOG_FILE = 'log/presort_bin_tipped.log'
  PRESORT_BIN_TIPPED_LOG = Logger.new(PRESORT_BIN_TIPPED_LOG_FILE, 10, 1_024_000)

  # Logs requests, responses and errors for create bin service (Keep history: 10 files of up to 1Mb each)
  PRESORT_BIN_CREATED_LOG_FILE = 'log/presort_bin_created.log'
  PRESORT_BIN_CREATED_LOG = Logger.new(PRESORT_BIN_CREATED_LOG_FILE, 10, 1_024_000)

  # labeling cached setup data path
  LABELING_CACHED_DATA_FILEPATH = File.expand_path('../tmp/run_cache', __dir__)

  # General
  DEFAULT_KEY = 'DEFAULT'

  # Integration
  raise 'RMT Integration server uri is required' if CR_PROD.integrate_with_external_rmt_system && !RMT_INTEGRATION_SERVER_URI

  # Constants for pallet movements:
  BUILDUP_PALLET_MIX = 'BUILDUP'
  PALLETIZING_PALLET_MIX = 'PALLETIZING'
  PALLETIZING_BAYS_PALLET_MIX = 'PALLETIZING_BAYS'
  PALLET_MIX_RULES = [BUILDUP_PALLET_MIX,
                      PALLETIZING_PALLET_MIX,
                      PALLETIZING_BAYS_PALLET_MIX].freeze

  # Constants for pallet statuses:
  PALLETIZED_NEW_PALLET = 'PALLETIZED_NEW_PALLET'
  RW_PALLET_SINGLE_EDIT = 'RW_PALLET_SINGLE_EDIT'
  RW_PALLET_BATCH_EDIT = 'RW_PALLET_BATCH_EDIT'
  PALLETIZED_SEQUENCE_ADDED = 'PALLETIZED_SEQUENCE_ADDED'
  PALLETIZED_SEQUENCE_REPLACED = 'PALLETIZED_SEQUENCE_REPLACED'
  PALLETIZED_SEQUENCE_UPDATED = 'PALLETIZED_SEQUENCE_UPDATED'
  PALLET_WEIGHED = 'PALLET WEIGHED'
  PALLET_MOVED = 'PALLET_MOVED'
  PALLET_SCRAPPED = 'PALLET SCRAPPED'
  PALLET_UNSCRAPPED = 'PALLET UNSCRAPPED'
  PALLETIZING = 'PALLETIZING'
  SEQUENCE_REMOVED_BY_CTN_TRANSFER = 'SEQUENCE_REMOVED_BY_CTN_TRANSFER'
  SCRAPPED_BY_BUILDUP = 'SCRAPPED_BY_BUILDUP'
  REPACK_SCRAP = 'REPACK_SCRAP'
  REPACKED = 'REPACKED'
  CREATED_FROM_BIN = 'CREATED_FROM_BIN'
  CONVERTED_TO_REBIN = 'CONVERTED_TO_REBIN'

  # Constants for bin_scan_mode:
  SCAN_BINS_INDIVIDUALLY = 1
  SCAN_BIN_GROUPS = 2
  AUTO_ALLOCATE_BIN_NUMBERS = 3
  BIN_SCAN_MODE_OPTIONS = [['Scan Bins Individually', SCAN_BINS_INDIVIDUALLY], ['Scan Bin Groups', SCAN_BIN_GROUPS], ['Auto Allocate Bin Numbers', AUTO_ALLOCATE_BIN_NUMBERS]].freeze

  # Constants for cartons:
  CARTON_TRANSFER = 'CARTON TRANSFER'
  SEQ_REMOVED_BY_CTN_TRANSFER = 'SEQUENCE REMOVED BY CARTON TRANSFER'
  PALLET_COMPLETED_ON_BAY = 'PALLET COMPLETED ON BAY'
  PALLET_RETURNED_TO_BAY = 'PALLET RETURNED TO BAY'
  PALLET_SCRAPPED_BY_CTN_TRANSFER = 'PALLET SCRAPPED BY CARTON TRANSFER'

  # Constants for stock types:
  PALLET_STOCK_TYPE = 'PALLET'
  BIN_STOCK_TYPE = 'BIN'

  # Constants for pallet build statuses:
  PALLET_FULL_BUILD_STATUS = 'FULL'

  # Constants for RMT delivery statuses:
  DELIVERY_TRIPSHEET_CREATED = 'TRIPSHEET_CREATED'
  DELIVERY_TRIPSHEET_CANCELED = 'TRIPSHEET_CANCELED'
  DELIVERY_TRIPSHEET_REFRESHED = 'TRIPSHEET_REFRESHED'
  DELIVERY_TRIPSHEET_OFFLOADED = 'TRIPSHEET_OFFLOADED'

  # Constants for RMT bin statuses:
  RMT_BIN_TIPPED_MANUALLY = 'TIPPED MANUALLY'
  RMT_BIN_WEIGHED_MANUALLY = 'WEIGHED MANUALLY'
  RMT_BIN_MOVED = 'BIN_MOVED'
  RMT_BIN_ADDED_TO_DELIVERY_TRIPSHEET = 'ADDED_TO_DELIVERY_TRIPSHEET'
  RMT_BIN_ADDED_TO_BINS_TRIPSHEET = 'ADDED_TO_BINS_TRIPSHEET'
  RMT_BIN_OFFLOADED = 'OFFLOADED'
  RMT_BIN_REMOVED_FROM_BINS_TRIPSHEET = 'REMOVED_FROM_BINS_TRIPSHEET'
  BIN_TRIPSHEET_CANCELED = 'TRIPSHEET_CANCELED'
  RMT_BIN_LOADED_ON_VEHICLE = 'LOADED_ON_VEHICLE'
  BULK_WEIGH_RMT_BINS = 'BULK WEIGH BINS MANUALLY'
  RMT_BIN_RECEIPT_DATE_OVERRIDE = 'RECEIPT DATE OVERRIDE'
  RMT_BIN_REFERENCE_NUMBER_OVERRIDE = 'REFERENCE NUMBER OVERRIDE'
  RMT_BIN_UNTIPPED_MANUALLY = 'UNTIPPED MANUALLY'
  CONVERTED_TO_PALLET = 'CONVERTED_TO_PALLET'
  CONVERTED_FROM_PALLET = 'CONVERTED_FROM_PALLET'
  REWORKS_ORCHARD_MIX = 'REWORKS ORCHARD MIX'

  # Constants for PKG Types
  PM_TYPE_STICKER = 'STICKER'
  PM_TYPE_LABOUR = 'LABOUR'
  PM_TYPE_BIN = 'BIN'
  PM_TYPE_CARTON = 'CARTON'

  # Constants for PKG Subtypes
  PM_SUBTYPE_FRUIT_STICKER = 'FRUIT_STICKER'
  PM_SUBTYPE_TU_STICKER = 'TU_STICKER'
  PM_SUBTYPE_RU_STICKER = 'RU_STICKER'
  PM_SUBTYPE_TU_LABOUR = 'TU_LABOUR'
  PM_SUBTYPE_RU_LABOUR = 'RU_LABOUR'
  PM_SUBTYPE_RI_LABOUR = 'RI_LABOUR'

  # Constants for pallets exit_ref
  PALLET_EXIT_REF_SCRAPPED = 'SCRAPPED'
  PALLET_EXIT_REF_SCRAPPED_BY_BUILDUP = 'SCRAPPED_BY_BUILDUP'
  PALLET_EXIT_REF_REMOVED = 'REMOVED'
  PALLET_EXIT_REF_REPACKED = 'REPACKED'
  PALLET_EXIT_REF_RESTORE_REPACKED_PALLET = 'RESTORE REPACKED PALLET'

  # Constants for rmt_bins exit_ref
  BIN_EXIT_REF_UNSCRAPPED = 'BIN UNSCRAPPED'
  BIN_EXIT_REF_SHIPPED = 'SHIPPED'

  # Constants for bin fullness
  BIN_FULL = 'Full'
  BIN_FULLNESS_OPTIONS = %w[Quarter Half Three\ Quarters Full].freeze

  # Constants for location assignments:
  WAREHOUSE_RECEIVING_AREA = 'WAREHOUSE_RECEIVING_AREA'
  PRESORTING = 'PRESORTING'

  # Constants for roles:
  ROLE_IMPLEMENTATION_OWNER = 'IMPLEMENTATION_OWNER'
  ROLE_CUSTOMER = 'CUSTOMER'
  ROLE_CUSTOMER_CONTACT_PERSON = 'CUSTOMER_CONTACT_PERSON'
  ROLE_SALES_PERSON = 'SALES_PERSON'
  ROLE_SUPPLIER = 'SUPPLIER'
  ROLE_MARKETER = 'MARKETER'
  ROLE_FARM_OWNER = 'FARM_OWNER'
  ROLE_RMT_BIN_OWNER = 'RMT_BIN_OWNER'
  ROLE_RMT_CUSTOMER = 'RMT_CUSTOMER'
  ROLE_SHIPPING_LINE = 'SHIPPING_LINE'
  ROLE_SHIPPER = 'SHIPPER'
  ROLE_FINAL_RECEIVER = 'FINAL_RECEIVER'
  ROLE_EXPORTER = 'EXPORTER'
  ROLE_BILLING_CLIENT = 'BILLING_CLIENT'
  ROLE_CONSIGNEE = 'CONSIGNEE'
  ROLE_HAULIER = 'HAULIER'
  ROLE_INSPECTOR = 'INSPECTOR'
  ROLE_INSPECTION_BILLING = 'INSPECTION_BILLING'
  ROLE_TARGET_CUSTOMER = 'TARGET CUSTOMER'
  ROLE_TRANSPORTER = 'TRANSPORTER'
  ROLE_FARM_MANAGER = 'FARM_MANAGER'

  PARTY_ROLE_REGISTRATION_TYPES = { 'LSP' => ROLE_SHIPPER,
                                    'CF' => ROLE_SHIPPER,
                                    'FBO' => ROLE_EXPORTER,
                                    'BILLING' => ROLE_INSPECTION_BILLING }.freeze

  # Target Market Type: 'PACKED'
  PACKED_TM_GROUP = 'PACKED'

  # Defaults for Packaging
  PM_TYPE_FRUIT = 'FRUIT'

  # Default UOM TYPE
  UOM_TYPE = 'INVENTORY'
  DEFAULT_UOM_CODE = 'EACH'

  # Constants for Reworks run types:
  RUN_TYPE_SINGLE_PALLET_EDIT = 'SINGLE PALLET EDIT'
  RUN_TYPE_BATCH_PALLET_EDIT = 'BATCH PALLET EDIT'
  RUN_TYPE_SCRAP_PALLET = 'SCRAP PALLET'
  RUN_TYPE_UNSCRAP_PALLET = 'UNSCRAP PALLET'
  RUN_TYPE_REPACK = 'REPACK PALLET'
  RUN_TYPE_BUILDUP = 'BUILDUP'
  RUN_TYPE_TIP_BINS = 'TIP BINS'
  RUN_TYPE_WEIGH_RMT_BINS = 'WEIGH RMT BINS'
  RUN_TYPE_RECALC_NETT_WEIGHT = 'RECALC NETT WEIGHT'
  RUN_TYPE_CHANGE_DELIVERIES_ORCHARDS = 'CHANGE DELIVERIES ORCHARDS'
  RUN_TYPE_SCRAP_BIN = 'SCRAP BIN'
  RUN_TYPE_UNSCRAP_BIN = 'UNSCRAP BIN'
  RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE = 'BULK PRODUCTION RUN UPDATE'
  RUN_TYPE_BULK_BIN_RUN_UPDATE = 'BULK BIN RUN UPDATE'
  RUN_TYPE_DELIVERY_DELETE = 'DELIVERY DELETE'
  RUN_TYPE_BULK_WEIGH_BINS = 'BULK WEIGH BINS'
  RUN_TYPE_BULK_UPDATE_PALLET_DATES = 'BULK UPDATE PALLET DATES'
  RUN_TYPE_UNTIP_BINS = 'UNTIP BINS'
  RUN_TYPE_RECALC_BIN_NETT_WEIGHT = 'RECALC BIN NETT WEIGHT'
  RUN_TYPE_TIP_MIXED_ORCHARDS = 'TIP MIXED ORCHARDS'
  RUN_TYPE_BINS_TO_PLT_CONVERSION = 'BINS TO PLT CONVERSION'
  RUN_TYPE_CHANGE_RUN_ORCHARD = 'CHANGE RUN ORCHARD'
  RUN_TYPE_BATCH_PRINT_LABELS = 'BATCH PRINT LABELS'
  RUN_TYPE_TIP_BINS_AGAINST_SUGGESTED_RUN = 'TIP BINS AGAINST SUGGESTED RUN'
  RUN_TYPE_RESTORE_REPACKED_PALLET = 'RESTORE REPACKED PALLET'
  RUN_TYPE_CHANGE_BIN_DELIVERY = 'CHANGE BIN DELIVERY'
  RUN_TYPE_CHANGE_RUN_CULTIVAR = 'CHANGE RUN CULTIVAR'
  RUN_TYPE_SINGLE_BIN_EDIT = 'SINGLE BIN EDIT'
  RUN_TYPE_SCRAP_CARTON = 'SCRAP CARTON'
  RUN_TYPE_UNSCRAP_CARTON = 'UNSCRAP CARTON'

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
  REWORKS_ACTION_BULK_PALLET_RUN_UPDATE = 'BULK PALLET RUN UPDATE'
  REWORKS_ACTION_BULK_BIN_RUN_UPDATE = 'BULK BIN RUN UPDATE'
  REWORKS_ACTION_CHANGE_DELIVERIES_ORCHARDS = 'CHANGE DELIVERIES ORCHARDS'
  REWORKS_ACTION_SCRAP_CARTON = 'SCRAP CARTON'
  REWORKS_ACTION_CHANGE_RUN_ORCHARD = 'CHANGE RUN ORCHARD'
  REWORKS_ACTION_CHANGE_BIN_DELIVERY = 'CHANGE BIN DELIVERY'
  REWORKS_ACTION_CHANGE_RUN_CULTIVAR = 'CHANGE RUN CULTIVAR'
  REWORKS_ACTION_SINGLE_BIN_EDIT = 'SINGLE BIN EDIT'

  REWORKS_REPACK_PALLET_STATUS = 'REPACK SCRAP'
  REWORKS_REPACK_PALLET_NEW_STATUS = 'REPACKED'
  REWORKS_SCRAPPED_STATUS = 'SCRAPPED'
  REWORKS_REPACK_SCRAP_REASON = 'REPACKED'
  REWORKS_BINS_CONVERTED_TO_PALLETS_SCRAP_REASON = 'BINS_CONVERTED_TO_PALLETS'
  REWORKS_RESTORE_REPACKED_PALLET_STATUS = 'RESTORED REPACKED PALLET'

  REWORKS_MOVE_BIN_BUSINESS_PROCESS = 'REWORKS_MOVE_BIN'
  BIN_TIP_MOVE_BIN_BUSINESS_PROCESS = 'BIN_TIP_MOVE_BIN'
  BIN_OFFLOAD_VEHICLE_MOVE_BIN_BUSINESS_PROCESS = 'MOVE_BIN'
  REWORKS_MOVE_PALLET_BUSINESS_PROCESS = 'MOVE_PALLET'
  DELIVERY_TRIPSHEET_BUSINESS_PROCESS = 'DELIVERY_TRIPSHEET'
  BINS_TRIPSHEET_BUSINESS_PROCESS = 'BINS_TRIPSHEET'
  PRESORT_STAGING_BUSINESS_PROCESS = 'PRESORT_STAGING'
  REWORKS_BULK_UPDATE_PALLET_DATES = 'REWORKS BULK UPDATE PALLET DATES'

  REWORKS_RUN_NON_PALLET_RUNS = {
    RUN_TYPE_TIP_BINS => :bin,
    RUN_TYPE_WEIGH_RMT_BINS => :bin,
    RUN_TYPE_SCRAP_BIN => :bin,
    RUN_TYPE_UNSCRAP_BIN => :bin,
    RUN_TYPE_BULK_WEIGH_BINS => :bin,
    RUN_TYPE_UNTIP_BINS => :bin,
    RUN_TYPE_TIP_MIXED_ORCHARDS => :bin,
    RUN_TYPE_SINGLE_BIN_EDIT => :bin,
    RUN_TYPE_CHANGE_BIN_DELIVERY => :bin,
    RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE => :prodrun,
    RUN_TYPE_BULK_BIN_RUN_UPDATE => :prodrun,
    RUN_TYPE_SCRAP_CARTON => :carton,
    RUN_TYPE_UNSCRAP_CARTON => :carton
  }.freeze

  # Routes that do not require login:
  BYPASS_LOGIN_ROUTES = [
    '/masterfiles/config/label_templates/published',
    '/messcada/.*',
    '/dashboard/.*',
    '/finished_goods/titan/titan_inspection_results_post_back'
  ].freeze

  # Menu
  FUNCTIONAL_AREA_RMD = 'RMD'

  # Logging
  FIELDS_TO_EXCLUDE_FROM_DIFF = %w[label_json png_image].freeze

  # MesServer
  raise 'LABEL_SERVER_URI must end with a "/"' unless LABEL_SERVER_URI.end_with?('/')

  POST_FORM_BOUNDARY = 'AaB03x'

  COST_UNITS = %w[BIN PALLET LOAD DELIVERY].freeze

  # Printers
  PRINTER_USE_INDUSTRIAL = 'INDUSTRIAL'
  PRINTER_USE_OFFICE = 'OFFICE'

  PRINT_APP_LOCATION = 'Location'
  PRINT_APP_BIN = 'Bin'
  PRINT_APP_REBIN = 'Rebin'
  PRINT_APP_CARTON = 'Carton'
  PRINT_APP_PALLET = 'Pallet'
  PRINT_APP_PALLET_TRIPSHEET = 'Pallet Tripsheet'
  PRINT_APP_PACKPOINT = 'Packpoint'
  PRINT_APP_PERSONNEL = 'Personnel'

  PRINTER_APPLICATIONS = [
    PRINT_APP_LOCATION,
    PRINT_APP_BIN,
    PRINT_APP_REBIN,
    PRINT_APP_CARTON,
    PRINT_APP_PALLET,
    PRINT_APP_PALLET_TRIPSHEET,
    PRINT_APP_PACKPOINT,
    PRINT_APP_PERSONNEL
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
    # { regex: '^(\\D\\D\\D)$', type: 'location', field: 'location_short_code' },
    # { regex: '^(\\D\\D\\D)$', type: 'dummy', field: 'code' },
    # { regex: '^SK(\\d+)', type: 'sku', field: 'sku_number' },
    { regex: '^DN(\\d+)', type: 'delivery', field: 'delivery_number' },
    { regex: '^BN(\\d+)', type: 'bin', field: 'id' },
    { regex: '^(\\d+)', type: 'pallet_number', field: 'pallet_number' },
    { regex: '^(\\d+)', type: 'carton_label_id', field: 'id' },
    # { regex: '^SK(\\d+)', type: 'bin_asset', field: 'bin_asset_number' }, # asset no should change to string and this should not require SK.
    { regex: '^([A-Z0-9]+)', type: 'bin_asset', field: 'bin_asset_number' }, # asset no should change to string and this should not require SK.
    { regex: '^(\\d+)', type: 'load', field: 'id' },
    { regex: '^(\\d+)', type: 'vehicle_job', field: 'id' }
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

  # Mail
  EMAIL_GROUP_LABEL_APPROVERS = 'label_approvers'
  EMAIL_GROUP_LABEL_PUBLISHERS = 'label_publishers'
  EMAIL_GROUP_EDI_NOTIFIERS = 'edi_notifiers'
  EMAIL_WORK_ORDER_MANAGERS = 'work_order_managers'
  USER_EMAIL_GROUPS = [EMAIL_GROUP_LABEL_APPROVERS, EMAIL_GROUP_LABEL_PUBLISHERS, EMAIL_GROUP_EDI_NOTIFIERS, EMAIL_WORK_ORDER_MANAGERS].freeze

  # Business Processes
  PROCESS_ADHOC_TRANSACTIONS = 'ADHOC_TRANSACTIONS'
  PROCESS_RECEIVE_EMPTY_BINS = 'RECEIVE_EMPTY_BINS'
  PROCESS_ISSUE_EMPTY_BINS = 'ISSUE_EMPTY_BINS'

  # Storage Types
  STORAGE_TYPE_PALLETS = 'PALLETS'
  STORAGE_TYPE_BIN_ASSET = 'BIN_ASSET'
  STORAGE_TYPE_BINS = 'BINS'
  EMPTY_BIN_STORAGE = 'EMPTY_BIN_STORAGE'

  # Locations: Location Types
  LOCATION_TYPES_WAREHOUSE = 'WAREHOUSE'
  LOCATION_TYPES_RECEIVING_BAY = 'RECEIVING BAY'
  LOCATION_TYPES_BIN_ASSET = 'BIN_ASSET'
  LOCATION_TYPES_FARM = 'FARM'

  ONSITE_EMPTY_BIN_LOCATION = 'ONSITE_EMPTY_BIN'
  ONSITE_FULL_BIN_LOCATION = 'ONSITE_FULL_BIN'

  PENDING_LOCATION = 'PENDING_LOCATION'

  # Loads:
  IN_TRANSIT_LOCATION = 'IN_TRANSIT_EX_PACKHSE'
  SCRAP_LOCATION = 'SCRAP_PACKHSE'
  UNSCRAP_LOCATION = 'UNSCRAP_PACKHSE'
  UNTIP_LOCATION = 'UNTIPPED_BIN'
  # Constants for port types:
  PORT_TYPE_POL = 'POL'
  PORT_TYPE_POD = 'POD'

  ROBOT_MSG_SEP = '###'

  BIG_ZERO = BigDecimal('0')
  # The maximum size of an integer in PostgreSQL
  MAX_DB_INT = 2_147_483_647

  # The maximum weight of a pallet
  MAX_PALLET_WEIGHT = 2000

  # The maximum weight of a bin
  MAX_BIN_WEIGHT = 2000

  # ISO 2-character country codes
  ISO_COUNTRY_CODES = %w[
    AF AL DZ AS AD AO AI AQ AG AR AM AW AU AT AZ BS BH BD BB BY BE BZ BJ
    BM BT BO BQ BA BW BV BR IO BN BG BF BI CV KH CM CA KY CF TD CL CN CX
    CC CO KM CD CG CK CR HR CU CW CY CZ CI DK DJ DM DO EC EG SV GQ ER EE
    SZ ET FK FO FJ FI FR GF PF TF GA GM GE DE GH GI GR GL GD GP GU GT GG
    GN GW GY HT HM VA HN HK HU IS IN ID IR IQ IE IM IL IT JM JP JE JO KZ
    KE KI KP KR KW KG LA LV LB LS LR LY LI LT LU MO MG MW MY MV ML MT MH
    MQ MR MU YT MX FM MD MC MN ME MS MA MZ MM NA NR NP NL NC NZ NI NE NG
    NU NF MP NO OM PK PW PS PA PG PY PE PH PN PL PT PR QA MK RO RU RW RE
    BL SH KN LC MF PM VC WS SM ST SA SN RS SC SL SG SX SK SI SB SO ZA GS
    SS ES LK SD SR SJ SE CH SY TW TJ TZ TH TL TG TK TO TT TN TR TM TC TV
    UG UA AE GB UM US UY UZ VU VE VN VG VI WF EH YE ZM ZW AX
  ].freeze

  DASHBOARD_INTERNAL_PAGES = [
    ['Carton Pallet summary per day', '/production/dashboards/carton_pallet_summary_days?fullpage=y'],
    ['Carton Pallet summary per week', '/production/dashboards/carton_pallet_summary_weeks?fullpage=y'],
    ['Deliveries per day', '/production/dashboards/delivery_days?fullpage=y'],
    ['Deliveries per week', '/production/dashboards/delivery_weeks?fullpage=y'],
    ['Device allocation', '/production/dashboards/device_allocation/$:ROBOT_BUTTON$?fullpage=y'],
    ['Loads per day', '/production/dashboards/load_days?fullpage=y'],
    ['Loads per week', '/production/dashboards/load_weeks?fullpage=y'],
    ['Palletizing bay states', '/production/dashboards/palletizing_bays?fullpage=y'],
    ['Pallets in stock', '/production/dashboards/in_stock?fullpage=y'],
    ['Production runs', '/production/dashboards/production_runs?fullpage=y']
  ].freeze

  DASHBOARD_QUERYSTRING_PARAMS = {
    'Production runs' => [{ key: 'LINE', optional: true }]
  }.freeze

  # EDI Settings
  EDI_FLOW_PS = 'PS'
  EDI_FLOW_PO = 'PO'
  EDI_FLOW_LI = 'LI'
  EDI_FLOW_UISTK = 'UISTK'
  EDI_FLOW_PALBIN = 'PALBIN'
  EDI_FLOW_HBS = 'HBS'
  EDI_FLOW_HCS = 'HCS'
  DEPOT_DESTINATION_TYPE = 'DEPOT'
  PARTY_ROLE_DESTINATION_TYPE = 'PARTY_ROLE'
  DESTINATION_TYPES = [DEPOT_DESTINATION_TYPE, PARTY_ROLE_DESTINATION_TYPE].freeze
  EDI_OUT_RULES_TEMPLATE = {
    EDI_FLOW_PS => {
      singleton: false,
      depot: false,
      roles: [ROLE_MARKETER, ROLE_TARGET_CUSTOMER]
    },
    EDI_FLOW_PO => {
      singleton: false,
      depot: true,
      roles: [ROLE_CUSTOMER, ROLE_SHIPPER, ROLE_EXPORTER]
    },
    EDI_FLOW_HBS => {
      singleton: true,
      depot: false,
      roles: []
    },
    EDI_FLOW_HCS => {
      singleton: false,
      depot: false,
      roles: [ROLE_EXPORTER]
    },
    EDI_FLOW_UISTK => {
      singleton: false,
      depot: false,
      roles: [ROLE_MARKETER]
    },
    EDI_FLOW_PALBIN => {
      singleton: false,
      depot: true,
      roles: [ROLE_CUSTOMER, ROLE_EXPORTER]
    }
  }.freeze

  MF_VARIANT_RULES = {
    Basic_Packs: { table_name: 'basic_pack_codes', column_name: 'basic_pack_code' },
    Cities: { table_name: 'destination_cities', column_name: 'city_name' },
    Commodities: { table_name: 'commodities', column_name: 'code' },
    Cultivars: { table_name: 'cultivars', column_name: 'cultivar_name' },
    Depots: { table_name: 'depots', column_name: 'depot_code' },
    Farms: { table_name: 'farms', column_name: 'farm_code' },
    Fruit_Size_References: { table_name: 'fruit_size_references', column_name: 'size_reference' },
    Grades: { table_name: 'grades', column_name: 'grade_code' },
    Inner_PKG_Marks: { table_name: 'inner_pm_marks', column_name: 'inner_pm_mark_code' },
    Inventory_Codes: { table_name: 'inventory_codes', column_name: 'inventory_code' },
    Locations: { table_name: 'locations', column_name: 'location_short_code' },
    Marketing_Varieties: { table_name: 'marketing_varieties',  column_name: 'marketing_variety_code' },
    Marks: { table_name: 'marks', column_name: 'mark_code' },
    Orchards: { table_name: 'orchards', column_name: 'orchard_code' },
    Organizations: { table_name: 'organizations', column_name: 'short_description' },
    PUCs: { table_name: 'pucs', column_name: 'puc_code' },
    Packed_TM_Group: { table_name: 'target_market_groups', column_name: 'target_market_group_name' },
    Plant_Resources: { table_name: 'plant_resources', column_name: 'plant_resource_code' },
    Ports: { table_name: 'ports', column_name: 'port_code' },
    RMT_Classes: { table_name: 'rmt_classes', column_name: 'rmt_class_code' },
    RMT_Delivery_Destinations: { table_name: 'rmt_delivery_destinations', column_name: 'delivery_destination_code' },
    RMT_Sizes: { table_name: 'rmt_sizes', column_name: 'size_code' },
    Seasons: { table_name: 'seasons', column_name: 'season_code' },
    Standard_Packs: { table_name: 'standard_pack_codes', column_name: 'standard_pack_code' },
    Target_Markets: { table_name: 'target_markets', column_name: 'target_market_name' },
    Vessels: { table_name: 'vessels', column_name: 'vessel_code' },
    RMT_Container_Material_Types: { table_name: 'rmt_container_material_types', column_name: 'container_material_type_code' }
  }.freeze

  MF_TRANSFORMATION_SYSTEMS = ['Kromco MES'].freeze
  MF_TRANSFORMATION_RULES = {
    Basic_Packs: { table_name: 'basic_pack_codes', column_name: 'basic_pack_code' },
    Cities: { table_name: 'destination_cities', column_name: 'city_name' },
    Commodities: { table_name: 'commodities', column_name: 'code' },
    Cultivars: { table_name: 'cultivars', column_name: 'cultivar_name' },
    Depots: { table_name: 'depots', column_name: 'depot_code' },
    Farms: { table_name: 'farms', column_name: 'farm_code' },
    Fruit_Size_References: { table_name: 'fruit_size_references', column_name: 'size_reference' },
    Grades: { table_name: 'grades', column_name: 'grade_code' },
    Inner_PKG_Marks: { table_name: 'inner_pm_marks', column_name: 'inner_pm_mark_code' },
    Inventory_Codes: { table_name: 'inventory_codes', column_name: 'inventory_code' },
    Locations: { table_name: 'locations', column_name: 'location_short_code' },
    Marketing_Varieties: { table_name: 'marketing_varieties',  column_name: 'marketing_variety_code' },
    Marks: { table_name: 'marks', column_name: 'mark_code' },
    Orchards: { table_name: 'orchards', column_name: 'orchard_code' },
    Organizations: { table_name: 'organizations', column_name: 'short_description' },
    PUCs: { table_name: 'pucs', column_name: 'puc_code' },
    Packed_TM_Group: { table_name: 'target_market_groups', column_name: 'target_market_group_name' },
    Ports: { table_name: 'ports', column_name: 'port_code' },
    RMT_Classes: { table_name: 'rmt_classes', column_name: 'rmt_class_code' },
    RMT_Delivery_Destinations: { table_name: 'rmt_delivery_destinations', column_name: 'delivery_destination_code' },
    RMT_Sizes: { table_name: 'rmt_sizes', column_name: 'size_code' },
    Seasons: { table_name: 'seasons', column_name: 'season_code' },
    Standard_Packs: { table_name: 'standard_pack_codes', column_name: 'standard_pack_code' },
    Target_Markets: { table_name: 'target_markets', column_name: 'target_market_name' },
    Vessels: { table_name: 'vessels', column_name: 'vessel_code' }
  }.freeze

  # Titan: Govt Inspections
  TITAN_API_HOST = { UAT: 'https://uatapigateway.ppecb.com',
                     STAGING: 'https://stagingapigateway.ppecb.com',
                     PRODUCTION: 'https://apigateway.ppecb.com' }[TITAN_ENVIRONMENT.to_sym]

  TITAN_ADDENDUM_REQUEST = 'Request Addendum'
  TITAN_ADDENDUM_STATUS = 'Addendum Status'
  TITAN_ADDENDUM_CANCEL = 'Cancel Addendum'

  # Constants for titan_protocol_exception:
  TITAN_PROTOCOL_EXCEPTION_OPTIONS = [
    ['SF - Smartfresh', 'SF'],
    ['7 - FCM', '7'],
    ['8 - CBS', '8'],
    ['9 - CFM & CBS', '9']
  ].freeze

  # QUALITY APP result types
  PASS_FAIL = 'Pass/Fail'
  CLASSIFICATION = 'Classification'
  QUALITY_RESULT_TYPE = [PASS_FAIL, CLASSIFICATION].freeze
  PHYT_CLEAN_STANDARD = 'PhytCleanStandardData'
  QUALITY_API_NAMES = [PHYT_CLEAN_STANDARD].freeze

  # PhytClean
  PHYT_CLEAN_ENVIRONMENT = 'https://www.phytclean.co.za'

  # eCert
  E_CERT_PROTOCOL = { QA: 'http://qa.', PRODUCTION: 'https://' }[E_CERT_ENVIRONMENT.to_sym]

  ASSET_TRANSACTION_TYPES = { adhoc_move: 'ADHOC_MOVE',
                              adhoc_create: 'ADHOC_CREATE',
                              adhoc_destroy: 'ADHOC_DESTROY',
                              receive: 'RECEIVE_BINS',
                              issue: 'ISSUE_BINS',
                              bin_tip: 'BIN_TIP',
                              rebin: 'REBIN' }.freeze

  # Complete Pallet
  PLT_LABEL_QTY_TO_PRINT = 4

  # Refresh pallet data
  REFRESH_PALLET_DATA_TABLES = %w[carton_labels pallet_sequences].freeze
  REFRESH_PALLET_DATA_COLUMNS = %w[fruit_actual_counts_for_pack_id fruit_size_reference_id].freeze
end
