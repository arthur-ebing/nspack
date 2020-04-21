# frozen_string_literal: true

module EdiApp
  class LiIn < BaseEdiInService
    attr_reader :org_code, :po_repo, :tot_cartons, :records

    def initialize(edi_in_transaction_id, file_path, logger)
      super(edi_in_transaction_id, file_path, logger)
    end

    def call
      puts 'LI in hash:'
      puts '-----------'
      p @edi_records

      ok_response
    end
  end
end
