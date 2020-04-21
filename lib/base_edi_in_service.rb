# frozen_string_literal: true

class BaseEdiInService < BaseService
  attr_reader :flow_type, :edi_in_transaction, :edi_records, :file_name, :logger

  def initialize(id, file_path, logger)
    @logger = logger
    @file_name = File.basename(file_path)
    repo = EdiApp::EdiInRepo.new
    @edi_in_transaction = repo.find_edi_in_transaction(id)
    @flow_type = edi_in_transaction.flow_type
    build_records(file_path)
  end

  def missing_required_fields(only_rows: nil)
    @flat_file_repo.missing_required_fields(only_rows: Array(only_rows))
  end

  def log(msg)
    logger.info "#{file_name}: #{msg}"
  end

  def log_err(msg)
    logger.error "#{file_name}: #{msg}"
  end

  private

  def build_records(file_path)
    file_type = check_file_type(file_path)
    if file_type == :xml
      @xml_file_repo = EdiApp::XmlFileRepo.new(flow_type)
      @xml_file_repo.validate_xml_schema(file_path)
      @edi_records = @xml_file_repo.records_from_file(file_path)
    else
      @flat_file_repo = EdiApp::FlatFileRepo.new(flow_type)
      # Validate file line lengths
      @edi_records = @flat_file_repo.records_from_file(file_path)
    end
  end

  def check_file_type(file_path)
    typ = IO.popen(['file', '--brief', '--mime-type', file_path], in: :close, err: :close) { |io| io.read.chomp }
    typ == 'application/xml' ? :xml : :text
  end
end
