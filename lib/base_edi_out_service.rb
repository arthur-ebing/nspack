# frozen_string_literal: true

class BaseEdiOutService < BaseService # rubocop:disable Metrics/ClassLength
  attr_reader :flow_type, :hub_address, :record_id, :seq_no, :schema, :record_definitions,
              :record_entries, :edi_out_rule_id, :party_role_id, :logger

  def initialize(flow_type, id, logger) # rubocop:disable Metrics/AbcSize
    raise ArgumentError, "#{self.class.name}: flow type must be provided" if flow_type.nil?

    @repo = EdiApp::EdiOutRepo.new
    edi_out_transaction = @repo.find_edi_out_transaction(id)
    @flow_type = edi_out_transaction.flow_type
    @logger = logger
    @party_role_id = edi_out_transaction.party_role_id
    @hub_address = edi_out_transaction.hub_address
    @record_id = edi_out_transaction.record_id
    @edi_out_rule_id = edi_out_transaction.edi_out_rule_id

    @seq_no = @repo.new_sequence_for_flow(flow_type)
    # PALTRACK REQUIREMENT: the sequence in EDI file name must be 3 characters.
    # So we convert the sequence to base 36 and left-pad with "A" if shorter than 3 characters.
    # The sequence will have to be reset after 46655.
    # @formatted_seq = format('%<seq>03d', seq: @seq_no)
    @formatted_seq = @seq_no.to_s(36).rjust(3, 'A')
    raise Crossbeams::FrameworkError, "Formatted sequence number cannot be longer than 3 chars. Seq is: #{@seq_no}, formatted as: #{@formatted_seq}" if @formatted_seq.length > 3

    @record_definitions = Hash.new { |h, k| h[k] = {} } # Hash.new { |h, k| h[k] = [] }
    @record_entries = Hash.new { |h, k| h[k] = [] }
    @output_filename = "#{@flow_type.upcase}#{AppConst::EDI_NETWORK_ADDRESS}#{@formatted_seq}.#{hub_address}"
    @mail_keys = []

    load_output_paths
    load_schema
  end

  # Reads an XML schema and compares each record size attribute against the sum of its field sizes.
  def self.check_schema_size_differences(flow_type) # rubocop:disable Metrics/AbcSize
    file_path = File.expand_path("edi/schemas/#{flow_type.downcase}.xml", __dir__)
    raise "There is no XML schema for EDI flow type #{flow_type}" unless File.exist?(file_path)

    required_sizes = schema_record_sizes[flow_type]

    schema = Nokogiri::XML(File.read(file_path))
    keys = schema.xpath('.//record/@identifier').map(&:value)

    out = {}
    keys.each do |key|
      rec_size = schema.xpath(".//record[@identifier='#{key}']/@size").map(&:value).first.to_i
      tot_size = schema.xpath(".//record[@identifier='#{key}']/fields/field/@size").map(&:value).map(&:to_i).sum
      out[key] = { rec: rec_size, fields: tot_size, required_size: required_sizes[key], xml_to_required_diff: required_sizes[key] - rec_size, diff: rec_size - tot_size }
    end
    out
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

    raise "Validation of #{flow_type} failed:\n#{@validation_errors.join("\n")}" unless @validation_errors.empty?

    ok_response
  end

  def build_hash_from_data(rec, rec_id)
    hs = {}
    record_definitions[rec_id].each_key { |key| hs[key] = rec[key] if rec[key] }
    hs
  end

  def add_csv_record(rec)
    row = {}
    record_definitions[flow_type].each_key do |name|
      row[name] = csv_value_for(name, rec[name])
    end
    record_entries[flow_type] << row
  end

  def add_record(record_type, rec = {})
    row = {}
    record_definitions[record_type].each_key do |name|
      row[name] = value_for(record_type, name, rec[name])
    end
    record_entries[record_type] << row
  end

  def create_csv_file # rubocop:disable Metrics/AbcSize
    @output_paths.each do |path|
      raise Crossbeams::FrameworkError, "The path '#{path}' does not exist for writing EDI files" unless File.exist?(path)

      keys = record_definitions[flow_type].keys
      CSV.open(File.join(path, @output_filename), 'w', headers: keys.map(&:to_s), write_headers: true) do |csv|
        record_entries[flow_type].each do |hash|
          csv << hash.values_at(*keys)
        end
      end
    end
    send_emails
    @output_filename
  end

  # This should be moved to a EdiOutFlatFileFormatter perhaps
  def create_flat_file
    lines = []
    record_entries.each_key do |key|
      lines += build_flat_rows(key)
    end

    @output_paths.each do |path|
      raise Crossbeams::FrameworkError, "The path '#{path}' does not exist for writing EDI files" unless File.exist?(path)

      File.open(File.join(path, @output_filename), 'w') { |f| f.puts lines.join("\n") }
    end
    send_emails
    @output_filename
  end

  def log(msg)
    logger.info "#{flow_type}: #{msg}"
  end

  def log_err(msg)
    logger.error "#{flow_type}: #{msg}"
  end

  private

  def schema_record_sizes
    required_sizes = @repo.schema_record_sizes[flow_type]
    # Flow type might point to another flow type (RL -> PO)
    required_sizes = @repo.schema_record_sizes[required_sizes] if required_sizes.is_a?(String)
    required_sizes
  end

  def csv_schema?
    schema_def = schema_record_sizes
    schema_def.length == 1 && schema_def['CSV']
  end

  def load_schema
    if csv_schema?
      @output_filename = "#{@output_filename}.csv"
      load_csv_schema
    else
      load_flat_schema
    end
  end

  def load_csv_schema
    file_path = File.expand_path("edi/schemas/#{flow_type.downcase}.yml", __dir__)
    raise "There is no YML schema for EDI flow type #{flow_type}" unless File.exist?(file_path)

    schema = YAML.load_file(file_path)
    schema.each do |key, val|
      record_definitions[flow_type][key] = val
    end
  end

  def load_flat_schema
    file_path = File.expand_path("edi/schemas/#{flow_type.downcase}.xml", __dir__)
    raise "There is no XML schema for EDI flow type #{flow_type}" unless File.exist?(file_path)

    @schema = Nokogiri::XML(File.read(file_path))
    record_keys = schema.xpath('.//record/@identifier').map(&:value)
    record_keys.each { |key| build_field_definitions(key) }
  end

  def load_output_paths
    dir_keys = @repo.edi_directory_keys(edi_out_rule_id)
    raise Crossbeams::FrameworkError, "There are no directory keys for EDI rule #{edi_out_rule_id}" if dir_keys.nil_or_empty?

    config = @repo.load_config
    build_mail_keys(config, dir_keys)

    build_edi_out_paths(config, dir_keys)
  end

  def build_mail_keys(config, dir_keys)
    @mail_keys = dir_keys.select { |k| k.start_with?('mail:') }.map { |m| m.delete_prefix('mail:') }.map(&:to_sym)
    return if @mail_keys.empty?

    unconfig_mails = @mail_keys.select { |k| config[:mail_recipients][k].nil? }
    raise Crossbeams::FrameworkError, "There is no :mail_recipients config with key(s) #{unconfig_emails.join(', ')}" unless unconfig_mails.nil_or_empty?
  end

  def build_edi_out_paths(config, dir_keys)
    @output_paths = []
    dir_keys.each do |key|
      if key.start_with?('mail:')
        path = build_edi_mail_out_path(config[:root], config[:email_dir])
        @output_paths << path unless @output_paths.include?(path)
      else
        build_edi_out_path(config[:root], config[:out_dirs][key.to_sym])
      end
    end
  end

  def build_edi_out_path(root, out_dest)
    base_path = root.sub('$HOME', ENV['HOME'])
    @output_paths << File.join(out_dest.sub('$ROOT', base_path), 'transmit')
  end

  def build_edi_mail_out_path(root, out_dest)
    raise Crossbeams::FrameworkError, 'The EDI out configuration does not include an entry for "email_dir"' if out_dest.nil?

    base_path = root.sub('$HOME', ENV['HOME'])
    out_dest.sub('$ROOT', base_path)
  end

  def send_emails
    config = @repo.load_config
    @mail_keys.each do |key|
      email_settings = config[:mail_recipients][key]
      email_settings[:subject] = "#{flow_type} file attached" unless email_settings[:subject]
      email_settings[:body] = "Attached please find #{flow_type} EDI file." unless email_settings[:body]
      path = build_edi_mail_out_path(config[:root], config[:email_dir])
      # p "Sending - #{key} from #{File.join(path, @output_filename)} to #{email_settings.inspect}"
      DevelopmentApp::SendMailJob.enqueue(email_settings.merge(attachments: [{ path: File.join(path, @output_filename) }]))
    end
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

  def csv_value_for(name, value)
    data_type = record_definitions[flow_type][name]
    data_type == :text ? "'#{value}" : value
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
      return s[0..len - 1]
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
end
