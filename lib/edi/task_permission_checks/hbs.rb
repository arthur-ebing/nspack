# frozen_string_literal: true

module EdiApp
  module TaskPermissionCheck
    class Hbs < BaseService
      attr_reader :task, :party_role_id, :record_id

      # Switch between rmt & fg...
      def initialize(task, party_role_id, record_id, context)
        @task = task
        @repo = if context[:fg_load]
                  FinishedGoodsApp::LoadRepo.new
                else
                  RawMaterialsApp::BinLoadRepo.new
                end
        @party_role_id = party_role_id
        @record_id = record_id
        @entity = if context[:fg_load]
                    @repo.find_load(@record_id)
                  else
                    @repo.find_bin_load(@record_id)
                  end
      end

      CHECKS = {
        send_edi: :send_edi_check
      }.freeze

      def call
        return failed_response("There is no bin load with id #{record_id}") unless @entity

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def send_edi_check
        return failed_response('This flow is not set to be used') unless AppConst::CR_EDI.send_hbs_edi

        ar = DB[:edi_out_rules].where(flow_type: AppConst::EDI_FLOW_HBS, active: true).select_map(:id)
        return success_response('ok', ar) unless ar.empty?

        failed_response("There is no destination for flow type #{AppConst::EDI_FLOW_HBS}")
      end
    end
  end
end
