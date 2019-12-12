# frozen_string_literal: true

module EdiApp
  module Job
    class SendEdiOut < BaseQueJob
      attr_reader :org_code, :record_id, :flow_type, :repo

      def run(flow_type, org_code, user_name, record_id = nil) # rubocop:disable Metrics/AbcSize
        @flow_type = flow_type
        @org_code = org_code
        @record_id = record_id
        unless should_send_edi?
          finish
          return
        end

        @repo = EdiOutRepo.new
        hub_address = work_out_hub_address(flow_type)
        id = repo.create_edi_out_transaction(flow_type, org_code, user_name, record_id, hub_address)
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

      def work_out_hub_address(flow_type)
        case flow_type
        when AppConst::EDI_FLOW_PO
          repo.hub_address_for_po(record_id)
        when AppConst::EDI_FLOW_PS
          repo.hub_address_for_ps(org_code)
        else
          raise Crossbeams::FrameworkError, "EDI out: no rule to generate Hub Address for flow '#{flow_type}'."
        end
      end

      def should_send_edi?
        conf_file = 'config/edi_flow_config.yml'
        return false unless File.exist?(conf_file)

        config = YAML.load_file(conf_file)
        return false if config.dig(:out, flow_type.to_sym).nil?

        true
      end
    end
  end
end
