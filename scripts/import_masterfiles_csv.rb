# frozen_string_literal: false

# What this script does:
# ----------------------
# imports masterfiles from a CSV file
# and generates SQL insert statements
#
# Reason for this script:
# -----------------------
# Dunbrody has a lot of masterfile records
# and will be strenuous to capture via the UI

require 'csv'

class ImportMasterfilesCsv < BaseScript # rubocop:disable Metrics/ClassLength
  attr_reader :table_name, :input_filename, :output_filename,
              :table_rules, :csv_data, :insert_statement

  def run  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return failed_response('Missing arguments') if args.nil_or_empty?

    @table_name = args.first
    @input_filename = args.last
    dir = 'masterfiles'
    @output_filename = "#{dir}/#{table_name}.sql"

    res = validate_files
    return res unless res.success

    res = set_table_definitions
    return res unless res.success

    res = read_csv
    return res unless res.success

    res = validate_required_columns
    return res unless res.success

    generate_insert_statement

    if debug_mode
      puts "SQL insert query:: #{insert_statement}"
    else
      Dir.mkdir(dir) unless Dir.exist?(dir)
      File.write(output_filename, insert_statement)
    end

    infodump = <<~STR
      Script: ImportMasterfilesCsv

      What this script does:
      ----------------------
      imports from a CSV file masterfile records and generates SQL insert statements

      Reason for this script:
      -----------------------
      Dunbrody has a lot of masterfile records and will be strenuous to capture via the UI

      Results:
      --------
      Creates Sql file #{output_filename}

      SQL insert query:
      #{insert_statement}
    STR

    log_infodump(:data_fix,
                 :masterfile_import,
                 :import_masterfiles_csv,
                 infodump)

    if debug_mode
      success_response('Dry run complete')
    else
      success_response('masterfiles imported')
    end
  end

  private

  MF_TABLE_DEFINATIONS = {
    marketing_varieties: { rules: { table_column_names: %w[marketing_variety_code description], required_columns: %w[marketing_variety_code description] } },
    cultivars: { rules: { table_column_names: %w[commodity_id cultivar_group_id cultivar_name description], required_columns: %w[commodity_code cultivar_group_code cultivar_name description], lookup_columns: %w[commodity_id cultivar_group_id] } },
    marketing_varieties_for_cultivars: { rules: { table_column_names: %w[cultivar_id marketing_variety_id], required_columns: %w[cultivar_name marketing_variety_code], lookup_columns: %w[cultivar_id marketing_variety_id] } },
    farms: { rules: { table_column_names: %w[farm_code owner_party_role_id pdn_region_id description], required_columns: %w[farm_owner_name farm_owner_surname production_region_code description primary_puc_code], lookup_columns: %w[pdn_region_id], lookup_party_role_columns: %w[owner_party_role_id] } },
    orchards: { rules: { table_column_names: %w[farm_id puc_id orchard_code cultivar_ids], required_columns: %w[farm_code puc_code orchard_code], lookup_columns: %w[farm_id puc_id], lookup_arrays: %w[farm_id puc_id] } },
    pucs: { rules: { table_column_names: %w[puc_code gap_code], required_columns: %w[puc_code] } },
    std_fruit_size_counts: { rules: { table_column_names: %w[commodity_id size_count_value size_count_description uom_id marketing_size_range_mm marketing_weight_range size_count_interval_group minimum_size_mm maximum_size_mm average_size_mm minimum_weight_gm maximum_weight_gm average_weight_gm], required_columns: %w[commodity_code size_count_value size_count_description uom], lookup_columns: %w[commodity_id uom_id] } },
    standard_pack_codes: { rules: { table_column_names: %w[standard_pack_code material_mass basic_pack_code_id], required_columns: %w[standard_pack_code material_mass], lookup_columns: %w[basic_pack_code_id] } },
    basic_pack_codes: { rules: { table_column_names: %w[basic_pack_code], required_columns: %w[basic_pack_code description] } },
    fruit_actual_counts_for_packs: { rules: { table_column_names: %w[std_fruit_size_count_id basic_pack_code_id actual_count_for_pack standard_pack_code_ids size_reference_ids], required_columns: %w[commodity_code size_count_value basic_pack_code actual_count_for_pack], lookup_columns: %w[std_fruit_size_count_id basic_pack_code_id], lookup_arrays: %w[standard_pack_code_ids size_reference_ids] } }
  }.freeze

  MF_COLUMN_LOOKUP_DEFINATIONS = {
    commodity_id: { subquery: 'SELECT id FROM commodities WHERE code = ?', values: 'SELECT code FROM commodities WHERE id = ?' },
    cultivar_group_id: { subquery: 'SELECT id FROM cultivar_groups WHERE cultivar_group_code = ?', values: 'SELECT cultivar_group_code FROM cultivar_groups WHERE id = ?' },
    cultivar_id: { subquery: 'SELECT id FROM cultivars WHERE cultivar_name = ?', values: 'SELECT cultivar_name FROM cultivars WHERE id = ?' },
    cultivar_ids: { subquery: 'SELECT array_agg(id) FROM cultivars WHERE cultivar_name IN ?', values: 'SELECT cultivar_name FROM cultivars WHERE id IN ?' },
    marketing_variety_id: { subquery: 'SELECT id FROM marketing_varieties WHERE marketing_variety_code = ?', values: 'SELECT marketing_variety_code FROM marketing_varieties WHERE id = ?' },
    farm_id: { subquery: 'SELECT id FROM farms WHERE farm_code = ?', values: 'SELECT farm_code FROM farms WHERE id = ?' },
    puc_id: { subquery: 'SELECT id FROM pucs WHERE puc_code = ?', values: 'SELECT puc_code FROM pucs WHERE id = ?' },
    basic_pack_code_id: { subquery: 'SELECT id FROM basic_pack_codes WHERE basic_pack_code = ?', values: 'SELECT basic_pack_code FROM basic_pack_codes WHERE id = ?' },
    standard_pack_code_id: { subquery: 'SELECT id FROM standard_pack_codes WHERE standard_pack_code = ?', values: 'SELECT standard_pack_code FROM standard_pack_codes WHERE id = ?' },
    standard_pack_code_ids: { subquery: 'SELECT array_agg(id) FROM standard_pack_codes WHERE standard_pack_code IN ?', values: 'SELECT standard_pack_code FROM standard_pack_codes WHERE id IN ?' },
    size_reference_ids: { subquery: 'SELECT array_agg(id) FROM fruit_size_references WHERE size_reference IN ?', values: 'SELECT size_reference FROM fruit_size_references WHERE id IN ?' },
    uom_id: { subquery: 'SELECT id FROM uoms WHERE uom_code = ?', values: 'SELECT uom_code FROM uoms WHERE id = ?' },
    farm_group_id: { subquery: 'SELECT id FROM farm_groups WHERE farm_group_code = ?', values: 'SELECT farm_group_code FROM farm_groups WHERE id = ?' },
    std_fruit_size_count_id: { subquery: 'SELECT id FROM std_fruit_size_counts WHERE size_count_value = ? AND commodity_id = (SELECT id FROM commodities WHERE code = ?)', values: 'SELECT s.size_count_value, c.code FROM std_fruit_size_counts s JOIN commodities c ON c.id = s.commodity_id WHERE s.id = ?' },
    owner_party_role_id: { subquery: 'SELECT id FROM party_roles WHERE person_id = ? AND role_id = ?', values: 'SELECT person_id,role_id FROM party_roles WHERE id = ?' },
    pdn_region_id: { subquery: 'SELECT id FROM production_regions WHERE production_region_code = ?', values: 'SELECT production_region_code FROM production_regions WHERE id = ?' },
    zzz: {}
  }.freeze

  COLUMN_CSV_MAP = {
    commodity_id: { column_name: 'commodity_code' },
    cultivar_group_id: { column_name: 'cultivar_group_code' },
    cultivar_id: { column_name: 'cultivar_name' },
    cultivar_ids: { column_name: 'cultivars' },
    marketing_variety_id: { column_name: 'marketing_variety_code' },
    farm_code: { column_name: 'description' },
    farm_id: { column_name: 'farm_code' },
    puc_id: { column_name: 'puc_code', params: %w[puc_code gap_code], create_table: 'pucs' },
    basic_pack_code_id: { column_name: 'basic_pack_code', params: %w[standard_pack_code], create_table: 'basic_pack_codes' },
    standard_pack_code_id: { column_name: 'standard_pack_code' },
    standard_pack_code_ids: { column_name: 'standard_pack_codes', alt_column: 'basic_pack_code_id' },
    size_reference_ids: { column_name: 'size_references' },
    uom_id: { column_name: 'uom' },
    pdn_region_id: { column_name: 'production_region_code' },
    std_fruit_size_count_id: { column_name: %w[size_count_value commodity_code] }
  }.freeze

  NUMERIC_COLUMNS = %i[size_count_value minimum_size_mm maximum_size_mm average_size_mm minimum_weight_gm maximum_weight_gm
                       average_weight_gm material_mass standard_size_count_value actual_count_for_pack].freeze

  ARRAY_PARAM_COLUMNS = %i[std_fruit_size_count_id].freeze

  def validate_files
    file = Pathname.new(input_filename)
    return failed_response("Input file #{file} does not have .csv extension") unless ext_is_ok?(file, '.csv')
    return failed_response("Input file #{file} does not exist") unless file_exists?(file)

    ok_response
  end

  def ext_is_ok?(filename, file_ext)
    filename.extname.casecmp(file_ext).zero?
  end

  def file_exists?(filename)
    filename.exist?
  end

  def set_table_definitions
    return failed_response("No table definitions set for table : #{table_name}") if MF_TABLE_DEFINATIONS[table_name.to_sym].nil_or_empty?

    @table_rules = MF_TABLE_DEFINATIONS[table_name.to_sym][:rules]

    ok_response
  end

  def read_csv
    @csv_data = CSV.read(input_filename, headers: true)
    return failed_response("CSV is file : #{input_filename} empty.") if csv_data.empty?

    ok_response
  end

  def validate_required_columns
    return failed_response('CSV does not have the exact required set of headers') if missing_required_columns?

    ok_response
  end

  def missing_required_columns?
    !(table_rules[:required_columns] - csv_data.headers).empty?
  end

  def generate_insert_statement
    query = ''
    csv_data.each do |row_data|
      query << "INSERT INTO #{table_name} (#{table_rules[:table_column_names].map(&:to_s).join(', ')}) VALUES( #{csv_data_row_values(row_data).map(&:to_s).join(', ')});\n"
      query << validate_farm_pucs(row_data) if table_name == 'farms'
    end
    @insert_statement = query
  end

  def csv_data_row_values(row_data)
    row_values = []

    table_rules[:table_column_names].each { |col| row_values << column_row_value(row_data, col) }
    row_values
  end

  def column_row_value(row_data, col)  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    csv_value = column_csv_value(row_data, col)

    return alt_column_value(row_data, col) if csv_value.nil_or_empty? && COLUMN_CSV_MAP.include?(col.to_sym) && !COLUMN_CSV_MAP[col.to_sym][:alt_column].nil_or_empty?

    if !table_rules[:lookup_columns].nil_or_empty? && table_rules[:lookup_columns].include?(col)
      validate_column_lookup_value(row_data, col, csv_value)
    elsif !table_rules[:lookup_arrays].nil_or_empty? && table_rules[:lookup_arrays].include?(col)
      validate_column_lookup_array_value(col, csv_value)
    elsif !table_rules[:lookup_party_role_columns].nil_or_empty? && table_rules[:lookup_party_role_columns].include?(col)
      validate_column_lookup_party_role_value(row_data)
    elsif csv_value.nil_or_empty?
      'NULL'
    elsif NUMERIC_COLUMNS.include?(col.to_sym)
      csv_value.to_s
    else
      "'#{csv_value.to_s.gsub("'", "''")}'"
    end
  end

  def column_csv_value(row_data, col)  # rubocop:disable Metrics/AbcSize
    return row_data[col] unless COLUMN_CSV_MAP.include?(col.to_sym) && !COLUMN_CSV_MAP[col.to_sym][:column_name].nil_or_empty?

    column_name = COLUMN_CSV_MAP[col.to_sym][:column_name]

    return array_csv_value(column_name, row_data) if ARRAY_PARAM_COLUMNS.include?(col.to_sym)

    row_data[column_name].nil_or_empty? ? nil : row_data[column_name]
  end

  def alt_column_value(row_data, col)
    column_row_value(row_data, COLUMN_CSV_MAP[col.to_sym][:alt_column])
  end

  def array_csv_value(column_name, row_data)
    vals = []
    column_name.each { |col_name| vals << row_data[col_name] }
    vals
  end

  def validate_column_lookup_value(row_data, col, val)
    return 'NULL' if val.to_s.nil_or_empty?

    rec = DB[MF_COLUMN_LOOKUP_DEFINATIONS[col.to_sym][:subquery], *val]
    create_record(row_data, col) if rec.empty?
    "(#{DB[MF_COLUMN_LOOKUP_DEFINATIONS[col.to_sym][:subquery], *val].sql})"
  end

  def validate_column_lookup_array_value(col, val)  # rubocop:disable Metrics/AbcSize
    return 'NULL' if  val.to_s.nil_or_empty?

    val = val.split('|').map(&:strip).reject(&:empty?)

    qry = MF_COLUMN_LOOKUP_DEFINATIONS[col.to_sym][:values]
    lkp_val = DB[qry, val.to_a].select_map
    if lkp_val.empty?
      "'{}'"
    else
      "(#{DB[MF_COLUMN_LOOKUP_DEFINATIONS[col.to_sym][:subquery], lkp_val].sql})"
    end
  end

  def validate_column_lookup_party_role_value(row_data)
    surname = row_data['farm_owner_surname']
    first_name = row_data['farm_owner_name']
    return nil if surname.nil_or_empty? || first_name.nil_or_empty?

    query = "SELECT id  FROM people WHERE surname = '#{surname}' AND first_name = '#{first_name}'"
    person_rec = DB[query].single_value
    create_party_role(surname, first_name) if person_rec.nil_or_empty?

    "(SELECT id FROM party_roles WHERE person_id = (SELECT id  FROM people WHERE surname = '#{surname}' AND first_name = '#{first_name}') AND role_id = (SELECT id FROM roles WHERE name = 'FARM_OWNER'))"
  end

  def create_party_role(surname, first_name)
    qry = "INSERT INTO parties (party_type) VALUES('P');"
    DB[qry].insert

    query = 'SELECT id  FROM parties ORDER BY id desc LIMIT 1'
    party_id = DB[query].single_value

    qry = "INSERT INTO people (party_id, surname, first_name, title) VALUES(#{party_id}, '#{surname}', '#{first_name}', 'MR');"
    DB[qry].insert

    qry = "INSERT INTO party_roles (party_id, role_id, person_id) VALUES(#{party_id}, (SELECT id FROM roles WHERE name = 'FARM_OWNER'), (SELECT id  FROM people WHERE surname = '#{surname}' AND first_name = '#{first_name}'));"
    puts qry
    DB[qry].insert
  end

  def validate_farm_pucs(row_data)
    farm_code = row_data['description']
    puc_code = row_data['primary_puc_code']
    gap_code = row_data['gap_code']
    return nil if farm_code.nil_or_empty? || puc_code.nil_or_empty?

    query = "SELECT id FROM pucs WHERE puc_code = '#{puc_code}'"
    puc_rec = DB[query].single_value

    if puc_rec.nil_or_empty?
      qry = "INSERT INTO pucs (puc_code, gap_code) VALUES('#{puc_code}', '#{gap_code}');"
      DB[qry].insert
    end

    "INSERT INTO farms_pucs (puc_id, farm_id) VALUES( (SELECT id FROM pucs WHERE puc_code = '#{puc_code}'), (SELECT id FROM farms WHERE farm_code = '#{farm_code}') );\n"
  end

  def create_record(row_data, col)  # rubocop:disable Metrics/AbcSize
    create_table = COLUMN_CSV_MAP[col.to_sym][:create_table].to_s
    return failed_response("No table definitions set for table  : #{create_table}.") if MF_TABLE_DEFINATIONS[create_table.to_sym].nil_or_empty?

    create_table_rules = MF_TABLE_DEFINATIONS[create_table.to_sym][:rules]

    param_vals = []
    column_names = COLUMN_CSV_MAP[col.to_sym][:params]
    column_names.each { |col_name| param_vals << column_csv_value(row_data, col_name) }

    values = param_vals.map(&:to_s).reject(&:empty?)
    qry = "INSERT INTO #{create_table} (#{create_table_rules[:table_column_names].map(&:to_s).join(', ')}) VALUES( '#{values.join(',')}');"
    DB[qry].insert
  end
end

# frozen_string_literal: true
