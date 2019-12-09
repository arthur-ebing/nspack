# frozen_string_literal: true

module EdiApp
  module Job
    class SendEdiOut < BaseQueJob
      def run(flow_type, org_code, user_name, record_id = nil) # rubocop:disable Metrics/AbcSize
        repo = EdiOutRepo.new
        id = repo.create_edi_out_transaction(flow_type, org_code, user_name, record_id)
        klass = "#{flow_type.capitalize}Out"

        begin
          repo.transaction do
            res = EdiApp.const_get(klass).send(:call, id)
            if res.success
              repo.log_edi_out_complete(id, res.instance)
            else
              repo.log_edi_out_failed(id, res.message)
            end
            finish
          end
        rescue StandardError => e
          repo.log_edi_out_error(id, e)
          ErrorMailer.send_exception_email(e, subject: "EDI out transform failed (#{flow_type} for #{org_code})")
          expire
        end
      end
    end
  end
end
