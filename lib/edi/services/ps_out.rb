# frozen_string_literal: true

# Thoughts:
# pass in dump_data bool. If true, Base will log data before validate into infodump.
# Other logging...
module EdiApp
  class PsOut < BaseEdiOutService
    attr_reader :ps_repo

    def initialize(edi_out_transaction_id, logger)
      @ps_repo = PsOutRepo.new
      super(AppConst::EDI_FLOW_PS, edi_out_transaction_id, logger)
    end

    def call
      log('Starting transform...')
      prepare_bh
      prepare_ps
      return success_response('No data for PS') if @ps_record_count.zero?

      prepare_bt
      validate_data({ 'PS' => %i[sscc sequence_number] }, check_lengths: true)
      fname = create_flat_file
      log('Ending transform...')
      success_response('PsOut was successful', fname)
    end

    private

    def prepare_bh
      add_record('BH')
    end

    def prepare_ps
      @ps_record_count = 0
      @total_cartons = 0

      ps_repo.ps_rows(party_role_id).each do |rec|
        hash = build_hash_from_data(rec, 'PS')
        if AppConst::PS_APPLY_SUBSTITUTES
          %i[original_account saftbin1 saftbin2 product_characteristic_code].each do |fld|
            hash[fld] = rec["substitute_for_#{fld}".to_sym]
          end
        end
        add_record('PS', hash)
        @ps_record_count += 1
        @total_cartons += rec[:carton_quantity]
      end
    end

    def prepare_bt
      add_record('BT',
                 record_count: @ps_record_count + 2,
                 ps_record_count: @ps_record_count,
                 total_cartons: @total_cartons)
    end
  end
end
