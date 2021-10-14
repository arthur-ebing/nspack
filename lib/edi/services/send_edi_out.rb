# frozen_string_literal: true

module EdiApp
  # Check if there is a reason to create an EDI flow.
  # If so, enqueue a SendEdiOut job.
  class SendEdiOut < BaseService
    attr_reader :flow_type, :party_role_id, :user_name, :record_id, :context

    def initialize(flow_type, party_role_id, user_name, record_id = nil, context: {})
      @flow_type = flow_type
      @party_role_id = party_role_id
      @user_name = user_name
      @record_id = record_id
      @context = context
    end

    def call
      send_edi = config.dig(:send_edi, flow_type.downcase.to_sym)
      return failed_response("Config is not set up to send #{flow_type} EDIs") unless send_edi

      send_job
    end

    private

    def send_job
      res = flow_has_destination?
      return res unless res.success

      res = should_send_specific_edi?

      if res.success
        res.instance.each do |rule_id|
          # Store context (a Hash) as a string to avoid param-parsing problems within Que:
          EdiApp::Job::SendEdiOut.enqueue(flow_type, party_role_id, user_name, record_id, rule_id, context.inspect)
        end
        success_response("#{flow_type} EDI has been added to the job queue.")
      else
        res
      end
    end

    def config
      EdiOutRepo.new.load_config
    end

    def flow_has_destination?
      EdiOutRepo.new.flow_has_destination?(flow_type)
    end

    def should_send_specific_edi? # rubocop:disable Metrics/AbcSize
      klass = "TaskPermissionCheck::#{flow_type.capitalize}"
      if EdiApp.const_defined?(klass)
        EdiApp.const_get(klass).call(:send_edi, party_role_id, record_id, context)
      else
        EdiOutRepo.new.flow_has_matching_rule(flow_type, party_role_ids: Array(party_role_id))
      end
    rescue Crossbeams::FrameworkError => e
      ErrorMailer.send_exception_email(e, subject: "#{self.class.name} - #{e.message}", message: "EDI OUT FLOW: #{flow_type}. From method: #{__method__}")
      puts e.message
      puts e.backtrace.join("\n")
      raise
    end
  end
end
