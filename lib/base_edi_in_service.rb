# frozen_string_literal: true

class BaseEdiInService < BaseService
  attr_reader :flow_type, :edi_in_transaction, :edi_records, :file_name, :logger

  def initialize(id, file_path, logger, edi_result)
    @logger = logger
    @edi_result = edi_result
    @file_name = File.basename(file_path)
    @_edi_in_repo = EdiApp::EdiInRepo.new
    @edi_in_transaction = @_edi_in_repo.find_edi_in_transaction(id)
    @flow_type = edi_in_transaction.flow_type
    build_records(file_path)
  end

  def missing_required_fields(only_rows: nil)
    @flat_file_repo.missing_required_fields(only_rows: Array(only_rows))
  rescue Crossbeams::InfoError => e
    @edi_result.schema_valid = false
    @edi_result.notes = e.message
    raise
  end

  def log(message)
    logger.info "#{file_name}: #{message}"
  end

  def log_err(message)
    logger.error "#{file_name}: #{message}"
  end

  def match_data_on(match_data)
    @edi_result.match_data = match_data
    if match_data.include?(',')
      @_edi_in_repo.match_data_on_list(edi_in_transaction.id, flow_type, match_data.split(','))
    else
      @_edi_in_repo.match_data_on(edi_in_transaction.id, flow_type, match_data)
    end
  end

  def prepare_array_for_match(array)
    if array.length == 1
      "#{array.first},"
    else
      array.join(',')
    end
  end

  def missing_masterfiles_detected(notes)
    @edi_result.has_missing_master_files = true
    @edi_result.notes = notes
  end

  def business_validation_passed
    @edi_result.valid = true
  end

  def discrepancies_detected(notes)
    @edi_result.has_discrepancies = true
    @edi_result.notes = notes
  end

  private

  def build_records(file_path)
    file_type = check_file_type(file_path)
    if file_type == :xml
      build_xml_records(file_path)
    elsif file_type == :csv
      build_csv_records(file_path)
    else
      build_flat_file_records(file_path)
    end
  end

  def build_csv_records(file_path)
    @csv_file_repo = EdiApp::CsvFileRepo.new(flow_type)
    res = @csv_file_repo.validate_csv_schema(file_path)
    if res.success
      @edi_result.schema_valid = true
    else
      @edi_result.schema_valid = false
      @edi_result.notes = "CSV validation error:\n\n#{res.message}:\n#{res.instance.join("\n")}"
      log_err(@edi_result.notes)
      raise Crossbeams::InfoError, 'Invalid CSV file'
    end
    @edi_records = @csv_file_repo.records_from_file(file_path)
  end

  def build_xml_records(file_path)
    @xml_file_repo = EdiApp::XmlFileRepo.new(flow_type)
    res = @xml_file_repo.validate_xml_schema(file_path)
    if res.success
      @edi_result.schema_valid = true
    else
      @edi_result.schema_valid = false
      @edi_result.notes = "Schema validation error:\n\n#{res.instance.join("\n")}"
      log_err(@edi_result.notes)
      raise Crossbeams::InfoError, 'Invalid Schema'
    end
    @edi_records = @xml_file_repo.records_from_file(file_path)
  end

  def build_flat_file_records(file_path)
    @flat_file_repo = EdiApp::FlatFileRepo.new(flow_type)
    # TODO: Validate file line lengths?
    @edi_result.schema_valid = true
    @edi_records = @flat_file_repo.records_from_file(file_path)
  end

  def check_file_type(file_path)
    typ = IO.popen(['file', '--brief', '--mime-type', file_path], in: :close, err: :close) { |io| io.read.chomp }
    return :xml if %w[application/xml text/xml].include?(typ)
    return :csv if typ == 'application/csv'
    return :csv if File.extname(file_path) == '.csv'

    :text
  end
end
