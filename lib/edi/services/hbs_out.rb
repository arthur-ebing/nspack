# frozen_string_literal: true

module EdiApp
  class HbsOut < BaseEdiOutService
    attr_reader :hbs_repo

    def initialize(edi_out_transaction_id, logger)
      @hbs_repo = HbsOutRepo.new
      super(AppConst::EDI_FLOW_HBS, edi_out_transaction_id, logger)
    end

    def output_file_prefix
      'bs_sales_export'
    end

    def call
      log('Starting transform...')
      prepare_data
      return success_response('No data for HBS') if record_entries.length.zero?

      @mail_tokens[:load_id] = record_id

      fname = create_csv_file
      hbs_repo.log_hbs_success(fname, record_id)
      log('Ending transform...')
      success_response('HbsOut was successful', fname)
    end

    def on_fail(message)
      hbs_repo.log_hbs_fail(record_id, message)
    end

    private

    def prepare_data
      # This might be from bin loads or FG loads...
      if out_context['fg_load']
        hbs_repo.hbs_fg_rows(record_id).each { |row| add_csv_record(row) }
      else
        hbs_repo.hbs_rmt_rows(record_id).each { |row| add_csv_record(row) }
      end
    end
  end
end
