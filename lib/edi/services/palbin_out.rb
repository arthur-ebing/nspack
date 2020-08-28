# frozen_string_literal: true

module EdiApp
  class PalbinOut < BaseEdiOutService
    attr_reader :org_code, :pb_repo

    def initialize(edi_out_transaction_id, logger)
      @pb_repo = EdiApp::PalbinOutRepo.new
      super(AppConst::EDI_FLOW_PALBIN, edi_out_transaction_id, logger)
    end

    def call # rubocop:disable Metrics/AbcSize
      log('Starting transform...')
      prepare_data
      return success_response('No data for PALBIN') if record_entries.length.zero?

      fname = create_csv_file
      pb_repo.store_edi_filename(fname, record_id)

      log('Ending transform...')
      success_response('PALBIN Out was successful', fname)
    rescue Crossbeams::InfoError => e
      log_palbin_fail(record_id, e.message)
      failed_response(e.message)
    end

    private

    def prepare_data
      pb_repo.palbin_details(record_id).each { |row| add_csv_record(row) }
    end
  end
end
