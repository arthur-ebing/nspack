# frozen_string_literal: true

module EdiApp
  class UistkOut < BaseEdiOutService
    attr_reader :ps_repo

    def initialize(edi_out_transaction_id, logger)
      super(AppConst::EDI_FLOW_UISTK, edi_out_transaction_id, logger)
    end

    def call
      log('Starting transform...')
      prepare_data
      return success_response('No data for UISTK') if record_entries.length.zero?

      # validate_data({ 'PS' => %i[sscc sequence_number] }, check_lengths: true)
      fname = create_csv_file
      log('Ending transform...')
      success_response('UistkOut was successful', fname)
    end

    private

    def prepare_data
      add_csv_record(pallet_number: '123456789012345678', pallet_sequence_number: 1, production_run_id: 1, chem: nil)
      add_csv_record(pallet_number: '123456789012345687', pallet_sequence_number: 1, production_run_id: 1, chem: 'LC')
    end
  end
end
