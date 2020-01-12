module EdiApp
  class PoIn < BaseEdiInService
    attr_reader :org_code, :po_repo

    def initialize(edi_in_transaction_id, file_path, logger)
      @po_repo = PoInRepo.new
      super(edi_in_transaction_id, file_path, logger)
    end

    def call
      p "Got: #{edi_records.length} recs"
      log "Got: #{edi_records.length} recs"
      ok_response
      # Build pallets...
    end
  end
end
