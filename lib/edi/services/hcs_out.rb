# frozen_string_literal: true

module EdiApp
  class HcsOut < BaseEdiOutService
    attr_reader :hcs_repo

    def initialize(edi_out_transaction_id, logger)
      @hcs_repo = HcsOutRepo.new
      super(AppConst::EDI_FLOW_HCS, edi_out_transaction_id, logger)
    end

    def call
      log('Starting transform...')
      prepare_data
      return success_response('No data for HCS') if record_entries.length.zero?

      fname = create_csv_file
      log('Ending transform...')
      success_response('HcsOut was successful', fname)
    end

    private

    def prepare_data
      hcs_repo.hcs_rows(record_id).each { |row| add_csv_record(row) }
    end
  end
end
