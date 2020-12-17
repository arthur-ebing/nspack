# frozen_string_literal: true

module EdiApp
  class MfgtIn < BaseEdiInService
    attr_reader :user, :repo, :records

    def initialize(edi_in_transaction_id, file_path, logger, edi_in_result)
      super(edi_in_transaction_id, file_path, logger, edi_in_result)
      @repo = EdiApp::EdiInRepo.new
      @user = OpenStruct.new(user_name: 'System')
    end

    def call
      missing_required_fields(only_rows: 'masterfile')

      business_validation_passed

      create_mfgt_records

      success_response('MfgtIn processed')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def create_mfgt_records
      repo.transaction do
        @edi_records.each do |params|
          res = EdiMfgtInSchema.call(params)
          raise Crossbeams::InfoError, "Validation error: #{res.messages}" if res.failure?

          repo.get_id_or_create_with_status(:gtins, 'MFGT_PROCESSED', res)
        end

        ok_response
      end
    end
  end
end
