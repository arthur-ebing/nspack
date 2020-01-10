# frozen_string_literal: true

class BaseEdiInService < BaseService
  attr_reader :flow_type, :edi_records

  def initialize(id, file_path)
    repo = EdiApp::EdiInRepo.new
    edi_in_transaction = repo.find_edi_in_transaction(id)
    @flow_type = edi_in_transaction.flow_type
    flat_file_repo = EdiApp::FlatFileRepo.new(flow_type)
    # Validate file line lengths
    @edi_records = flat_file_repo.records_from_file(file_path)
  end
end
