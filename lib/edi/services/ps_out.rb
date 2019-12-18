# frozen_string_literal: true

# Thoughts:
# pass in dump_data bool. If true, Base will log data before validate into infodump.
# Other logging...
module EdiApp
  class PsOut < BaseEdiOutService
    attr_reader :org_code, :repo

    def initialize(edi_out_transaction_id)
      @repo = PsOutRepo.new
      super(AppConst::EDI_FLOW_PS, edi_out_transaction_id)
    end

    def call
      prepare_bh
      prepare_ps
      return success_response('No data for PS') if @ps_record_count.zero?

      prepare_bt
      validate_data({ 'PS' => %i[sscc sequence_number] }, check_lengths: true)
      fname = create_flat_file
      success_response('PsOut was successful', fname)
    end

    private

    def prepare_bh
      add_record('BH')
    end

    def prepare_ps
      @ps_record_count = 0
      @total_cartons = 0

      repo.ps_rows(org_code).each do |rec|
        hash = build_hash_from_data(rec, 'PS')
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
