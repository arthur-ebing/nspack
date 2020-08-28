# frozen_string_literal: true

module EdiApp
  module TaskPermissionCheck
    class Palbin < BaseService
      attr_reader :task, :party_role_id, :record_id
      def initialize(task, party_role_id, record_id)
        @task = task
        @repo = FinishedGoodsApp::LoadRepo.new
        @party_role_id = party_role_id
        @record_id = record_id
        @entity = @repo.find_load(@record_id)
      end

      CHECKS = {
        send_edi: :send_edi_check
      }.freeze

      def call
        return failed_response("There is no load with id #{record_id}") unless @entity

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def send_edi_check
        EdiOutRepo.new.flow_has_matching_rule(AppConst::EDI_FLOW_PALBIN,
                                              depot_ids: Array(@entity.depot_id),
                                              party_role_ids: [@entity.customer_party_role_id,
                                                               @entity.exporter_party_role_id])
      end
    end
  end
end
