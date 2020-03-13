# frozen_string_literal: true

module EdiApp
  module Job
    class SendEdiOut < BaseQueJob
      attr_reader :repo, :edi_out_rule_id, :hub_address, :flow_type, :email_notifiers

      # No point in retrying
      self.maximum_retry_count = 0

      def run(flow_type, party_role_id, user_name, record_id, edi_out_rule_id) # rubocop:disable Metrics/AbcSize
        @email_notifiers = DevelopmentApp::UserRepo.new.email_addresses(user_email_group: AppConst::EMAIL_GROUP_EDI_NOTIFIERS)
        @flow_type = flow_type
        @edi_out_rule_id = edi_out_rule_id
        @repo = EdiOutRepo.new
        work_out_hub_address

        id = repo.create_edi_out_transaction(flow_type: flow_type,
                                             party_role_id: party_role_id,
                                             user_name: user_name,
                                             record_id: record_id,
                                             hub_address: hub_address,
                                             edi_out_rule_id: edi_out_rule_id)
        log("Transform started for party role '#{party_role_id}', record '#{record_id}', rule id '#{edi_out_rule_id}' and transaction id '#{id}'...")

        klass = "#{flow_type.capitalize}Out"
        transformer = EdiApp.const_get(klass).send(:new, id, logger)

        begin
          repo.transaction do
            res = transformer.call
            if res.success
              log "Completed: #{res.message}"
              repo.log_edi_out_complete(id, res.instance, res.message)
            else
              log "Failed: #{res.message}"
              repo.log_edi_out_failed(id, res.message)
              transformer.on_fail(res.message) if transformer.respond_to?(:on_fail)
            end
            finish
          end
        rescue StandardError => e
          log_err(e.message)
          repo.log_edi_out_error(id, e)
          ErrorMailer.send_exception_email(e, subject: "EDI out transform failed (#{flow_type} for rule: #{edi_out_rule_id})", append_recipients: email_notifiers)
          transformer.on_fail('an error occurred') if transformer&.respond_to?(:on_fail)
          expire
        end
      end

      def work_out_hub_address
        @hub_address = repo.hub_address_for(edi_out_rule_id)
      end

      def log(msg)
        logger.info "#{flow_type}: #{msg}"
      end

      def log_err(msg)
        logger.error "#{flow_type}: #{msg}"
      end

      def logger
        @logger ||= Logger.new(File.join(ENV['ROOT'], 'log', 'edi_out.log'), 'weekly')
      end
    end
  end
end
