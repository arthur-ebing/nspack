# frozen_string_literal: true

class BaseEdiOutService < BaseService # rubocop:disable Metrics/ClassLength
  attr_reader :flow_type, :org_code, :hub_address, :record_id, :seq_no, :schema, :record_definitions, :record_entries

  def initialize(flow_type, id) # rubocop:disable Metrics/AbcSize
    raise ArgumentError, "#{self.class.name}: flow type must be provided" if flow_type.nil?

    repo = EdiApp::EdiOutRepo.new
    edi_out_transaction = repo.find_edi_out_transaction(id)
    @flow_type = edi_out_transaction.flow_type
    @org_code = edi_out_transaction.org_code
    @hub_address = edi_out_transaction.hub_address
    @record_id = edi_out_transaction.record_id
    @seq_no = repo.new_sequence_for_flow(flow_type)
    @formatted_seq = format('%<seq>03d', seq: @seq_no)
    @record_definitions = Hash.new { |h, k| h[k] = {} } # Hash.new { |h, k| h[k] = [] }
    @record_entries = Hash.new { |h, k| h[k] = [] }
    @output_filename = "#{@flow_type.upcase}#{AppConst::EDI_NETWORK_ADDRESS}#{@formatted_seq}.#{hub_address}"

    load_output_paths
    load_schema
  end

  # Reads an XML schema and compares each record size attribute against the sum of its field sizes.
  def self.check_schema_size_differences(flow_type) # rubocop:disable Metrics/AbcSize
    file_path = File.expand_path("edi/schemas/#{flow_type.downcase}.xml", __dir__)
    raise "There is no XML schema for EDI flow type #{flow_type}" unless File.exist?(file_path)

    yml_path = File.expand_path('edi/schemas/schema_record_sizes.yml', __dir__)
    raise 'There is no schema_record_sizes.yml file' unless File.exist?(yml_path)

    schema = Nokogiri::XML(File.read(file_path))
    keys = schema.xpath('.//record/@identifier').map(&:value)
    required_sizes = YAML.load_file(yml_path)[flow_type]

    out = {}
    keys.each do |key|
      rec_size = schema.xpath(".//record[@identifier='#{key}']/@size").map(&:value).first.to_i
      tot_size = schema.xpath(".//record[@identifier='#{key}']/fields/field/@size").map(&:value).map(&:to_i).sum
      out[key] = { rec: rec_size, fields: tot_size, required_size: required_sizes[key], xml_to_required_diff: required_sizes[key] - rec_size, diff: rec_size - tot_size }
    end
    out
  end

  def load_schema
    file_path = File.expand_path("edi/schemas/#{flow_type.downcase}.xml", __dir__)
    raise "There is no XML schema for EDI flow type #{flow_type}" unless File.exist?(file_path)

    @schema = Nokogiri::XML(File.read(file_path))
    record_keys = schema.xpath('.//record/@identifier').map(&:value)
    record_keys.each { |key| build_field_definitions(key) }
  end

  def load_output_paths
    raise Crossbeams::FrameworkError, 'There is no EDI config file named "config/edi_flow_config.yml"' unless File.exist?('config/edi_flow_config.yml')

    config = YAML.load_file('config/edi_flow_config.yml')
    raise Crossbeams::FrameworkError, "There is no EDI config for #{flow_type} out transformation" if config.dig(:out, flow_type.to_sym).nil?

    build_edi_out_paths(config)
  end

  def build_edi_out_paths(config)
    @output_paths = []
    config[:out][flow_type.to_sym].each do |out_dest|
      build_edi_out_path(config[:root], out_dest)
    end
  end

  def build_edi_out_path(root, out_dest)
    return if out_dest[:except] && out_dest[:except][:org_code] == org_code

    base_path = root.sub('$HOME', ENV['HOME'])
    @output_paths << File.join(out_dest[:path].sub('$ROOT', base_path), 'transmit')
  end

  # Services can use the field definition:
  # - name        (the name as defined in the spec)
  # - offset      (for flat text records, the starting position)
  # - length      (the length of the field in characters)
  # - trim        (boolean: should the field be trimed to fit the length for a flat file?)
  # - required    (boolean: must the field be present)
  # - format      (rules for formatting the output)
  # - default     (the default value or nil)
  def build_field_definitions(key) # rubocop:disable Metrics/AbcSize
    field_nodes = schema.xpath(".//record[@identifier='#{key}']/fields/field")
    offset = 0
    field_nodes.each do |field_node|
      len = field_node['size'].to_i
      rec = OpenStruct.new(name: field_node['name'].to_s.to_sym,
                           offset: offset,
                           length: len,
                           required: field_node['required'] == 'true',
                           trim: field_node['trim'] == 'true',
                           format: field_node['format'])
      rec[:default] = field_node.attributes['default'].to_s if field_node.attributes['default']
      raise "There is already a rule for #{field_node['name']} in #{flow_type.downcase}.xml for #{key}. Please make it unique" unless record_definitions[key][field_node['name'].to_s.to_sym].nil?

      record_definitions[key][field_node['name'].to_s.to_sym] = rec
      offset += len
    end
    # Idea: perhaps build a Dry:Schema for validation?
  end

  # VALIDATE fixed len record size vs sum of fields... (include end_padding field)
  # send in "for fixed" and raise err if field leng too long after formatting
  def validate_data(identifiers, check_lengths = false)
    @validation_errors = []
    @identifiers = identifiers
    @check_lengths = check_lengths
    record_entries.each_key do |key|
      validate_entries(key)
    end

    raise "Validation of #{flow_type} failed - #{@validation_errors.join("\n")}" unless @validation_errors.empty?

    ok_response
  end

  def validate_entries(key)
    rules = record_definitions[key]
    record_entries[key].each do |rec|
      validate_row(key, rec, rules)
    end
  end

  def validate_row(rec_id, row, rules) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    row_desc = "#{rec_id} : "
    row_desc = "#{rec_id} : [#{@identifiers[rec_id].map { |field| "#{field} = #{row[field]}" }.join(', ')}]" if @identifiers[rec_id]

    errors = []
    rules.each do |key, rule|
      errors << "#{key} is missing" if rule.required && row[key].nil?
      errors << "#{key} length of \"#{row[key]}\" is longer than maxlength (#{rule.length})" if @check_lengths && row[key].is_a?(String) && !rule.trim && row[key].length > rule.length.to_i
    end
    @validation_errors << "#{row_desc} - #{errors.join(', ')}." unless errors.empty?
  end

  def add_record(record_type, rec = {})
    row = {}
    record_definitions[record_type].keys.each do |name|
      row[name] = value_for(record_type, name, rec[name])
    end
    record_entries[record_type] << row
  end

  def value_for(record_type, name, value)
    return prep_field(record_type, name) if value.nil?

    value
  end

  def prep_field(rec_type, key)
    rule = record_definitions[rec_type][key]
    return nil unless rule.default

    if rule.default.start_with?('$:')
      default_value_for(rule.default) # , rule.length, rule.format)
    else
      rule.default
    end
  end

  def default_value_for(code) # rubocop:disable Metrics/CyclomaticComplexity
    val = case code
          when '$:NOW$'
            Time.now
          when '$TODAY'
            Date.today
          when '$:BATCHNO$'
            seq_no
          when '$:NETWORK$'
            AppConst::EDI_NETWORK_ADDRESS
          when '$:INSTALL_LOCATION$'
            AppConst::INSTALL_LOCATION
          when '$:SOLAS_VERIFICATION_METHOD$'
            AppConst::SOLAS_VERIFICATION_METHOD
          when '$:SAMSA_ACCREDITATION$'
            AppConst::SAMSA_ACCREDITATION
          else
            raise ArgumentError, "BaseEdiOutService: Default code '#{code}' is unknown"
          end
    val
  end

  # Edi fields are placed into fixed-length records as strings. This module provides some shortcut formatting codes.
  # eg. +ZEROS+: left pads a field with zeroes up to the expected length.
  #
  # The format code is specified in the <tt>format=""</tt> attribute of the EDI in-transformer XML schema.
  # Formats:
  # _ZEROES_::    Left-pads a numeric with zeroes up to expected length. <b>(29 => 00029)</b> (-ve number will have - sign in place of left-most zero).
  # _DECIMAL_::   Left-pads a numeric with zeroes up to expected length. 2 decimal places. <b>(29.3 => 00029.30, -12.01 => 00012.01)</b> (-ve number will have - sign in place of left-most zero).
  # _SIGNED_::    Left-pads a numeric with zeroes up to expected length (with +/-sign). <b>(29 => +0029, -12 => -0012)</b>
  # _SIGNDEC_::   Left-pads a numeric with zeroes up to expected length (with +/-sign). 2 decimal places. <b>(29.3 => +0029.30, -12.01 => -0012.01)</b>
  # _TEMP_::      Temperature with sign. <b>(+23.45, -02.12)</b>
  # <em>TEMP1DEC</em>::  Temperature with sign and single decimal. <b>(+23.4, -02.1)</b>
  # _DATE_::      Date in YYYYMMDD format. <b>(20101225)</b>
  # _DATETIME_::  Date and time in YYYYMMDDHH:MM format. <b>(2010122513:45)</b>
  # _MMMDDYYYHMMAP_:: Date and time in MMM DD YYYY H:MMAM format. <b>(Jan 25 2011  8:57AM)</b>
  # _HMS_::       Time as Hours:Minutes:Seconds. <b>(13:45:05)</b>
  # _HM_::        Time as Hours:Minutes. <b>(13:45)</b>
  # module EdiFieldFormatter

  # Takes a raw value and returns a string representation using the format and desired length.
  #
  # The format can be a shortcut code (eg. +ZEROES+, +DATE+, +HMS+) or a valid Ruby +format+ string.
  # If no format is provided the value is treated as a string and right-padded with spaces
  # up to the required length of the field.
  #--
  # NB:: If you add a format to this method, make sure you list and describe it
  # at the top of this file.
  #++
  def format_flat_edi_field(raw_value, len, format_def, rec_type, key) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    # If no format provided, right-pad with spaces up to the field length.
    if format_def.nil?
      s = if raw_value.is_a?(BigDecimal)
            raw_value.to_s('F').ljust(len)
          else
            raw_value.to_s.ljust(len)
          end
      s[0..len - 1]
      return s
    end
    return ' ' * len if raw_value.nil?

    case format_def.upcase
    when 'ZEROES'
      format("%0#{len}d", raw_value)
    when 'DECIMAL'
      format("%0#{len}.2f", raw_value)
    when 'SIGNED'
      format("%+0#{len}d", raw_value)
    when 'SIGNDEC'
      format("%+0#{len}.2f", raw_value)
    when 'DATE' # Specify ISO etc
      raw_value.strftime('%Y%m%d')
    when 'DATETIME'
      raw_value.strftime('%Y%m%d%H:%M')
    when 'MMMDDYYYHMMAP'
      raw_value.strftime('%b %d %Y %l:%M%p')
    when 'HMS'
      raw_value.strftime('%H:%M:%S')
    when 'HM'
      raw_value.strftime('%H:%M')
    when 'TEMP' # +09.99, -09.99
      format("%+0#{len}.2f", raw_value)
    when 'TEMP1DEC' # +09.99, -09.99
      format("%+0#{len}.1f", raw_value)
    when '', nil # Default to string padded with zeroes on the right TODO: Check if default of padding to length is OK or error
      s = if raw_value.is_a?(BigDecimal)
            raw_value.to_s('F').ljust(len)
          else
            raw_value.to_s.ljust(len)
          end
      s[0..len - 1]
    else
      format(format_def, raw_value)
    end
  rescue StandardError => e
    raise Crossbeams::InfoError, "EDI OUT field format error for rec type \"#{rec_type}\", field \"#{key}\": #{e}"
  end

  # This should be moved to a EdiOutFlatFileFormatter perhaps
  def create_flat_file
    lines = []
    record_entries.each_key do |key|
      lines += build_flat_rows(key)
    end

    # puts lines.join("\n")
    @output_paths.each do |path|
      raise Crossbeams::FrameworkError, "The path '#{path}' does not exist for writing EDI files" unless File.exist?(path)

      File.open(File.join(path, @output_filename), 'w') { |f| f.puts lines.join("\n") }
    end
    @output_filename
  end

  def build_flat_rows(key)
    rules = record_definitions[key]
    lines = []
    record_entries[key].each do |row|
      lines << build_flat_row(rules, row, key)
    end
    lines
  end

  def build_flat_row(rules, row, rec_type)
    fields = []
    rules.each do |key, rule|
      fields << format_flat_edi_field(row[key], rule.length, rule.format, rec_type, key)
    end
    fields.join
  end

  def build_hash_from_data(rec, rec_id)
    hs = {}
    record_definitions[rec_id].keys.each { |key| hs[key] = rec[key] if rec[key] }
    hs
  end
end
