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
      store_edi_filename(fname, record_id)

      log('Ending transform...')
      success_response('PALBIN Out was successful', fname)
    rescue Crossbeams::InfoError => e
      log_palbin_fail(record_id, e.message)
      failed_response(e.message)
    end

    private

    def prepare_data
      palbins = pb_repo.palbin_details(record_id)

      # pallets with multiple sequences should not be allowed on palbin load
      multiple_sequences = palbins.map { |bin| bin[:sscc] }.length > palbins.map { |bin| bin[:sscc] }.uniq.length
      raise Crossbeams::InfoError, 'Palbin has multiple sequences' if multiple_sequences

      palbins.each { |row| add_csv_record(row) }
    end

    def store_edi_filename(file_name, record_id)
      pb_repo.update(:loads, record_id, edi_file_name: file_name)
      pb_repo.log_status(:loads, record_id, 'PALBIN SENT', user_name: 'System', comment: file_name)
    end

    def log_palbin_fail(record_id, message)
      pb_repo.log_status(:loads, record_id, 'PALBIN SEND FAILURE', user_name: 'System', comment: message)
    end
  end
end
