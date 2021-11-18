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

      @mail_tokens[:load_id] = record_id

      fname = create_csv_file
      hcs_repo.log_hcs_success(fname, record_id)
      log('Ending transform...')
      success_response('HcsOut was successful', fname)
    end

    def on_fail(message)
      hcs_repo.log_hcs_fail(record_id, message)
    end

    private

    def prepare_data
      hcs_repo.prepare_depot_pallet_cartons(record_id)
      first = true
      hcs_repo.hcs_rows(record_id).each do |row|
        if first
          @mail_tokens[:customer_order_no] = row[:customerpono]
          @mail_tokens[:container_code] = row[:container]
        end
        first = false
        add_csv_record(row)
      end
    end
  end
end
