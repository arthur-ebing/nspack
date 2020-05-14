# frozen_string_literal: true

module EdiApp
  class UistkOut < BaseEdiOutService
    attr_reader :uistk_repo

    def initialize(edi_out_transaction_id, logger)
      @uistk_repo = UistkOutRepo.new
      super(AppConst::EDI_FLOW_UISTK, edi_out_transaction_id, logger)
    end

    def call
      log('Starting transform...')
      prepare_data
      return success_response('No data for UISTK') if record_entries.length.zero?

      fname = create_csv_file
      log('Ending transform...')
      success_response('UistkOut was successful', fname)
    end

    private

    def prepare_data
      uistk_repo.uistk_rows(party_role_id).each { |row| add_csv_record(row) }
    end
  end
end
