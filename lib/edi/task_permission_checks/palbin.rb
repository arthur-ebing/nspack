# frozen_string_literal: true

module EdiApp
  module TaskPermissionCheck
    class Palbin < BaseService
      attr_reader :task, :party_role_id, :record_id

      def initialize(task, party_role_id, record_id, _context)
        @task = task
        @repo = FinishedGoodsApp::LoadRepo.new
        @party_role_id = party_role_id
        @record_id = record_id
        @entity = @repo.find_load(@record_id)
      end

      CHECKS = {
        send_edi: :send_edi_check
      }.freeze

      VALID_ROLES = {
        AppConst::ROLE_CUSTOMER => :customer_party_role_id,
        AppConst::ROLE_EXPORTER => :exporter_party_role_id
      }.freeze

      DEPOT_VALID = true

      def call
        return failed_response("There is no load with id #{record_id}") unless @entity

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def send_edi_check
        raise Crossbeams::FrameworkError, "AppConst::EDI_OUT_RULES_TEMPLATE is incorrectly set up for '#{AppConst::EDI_FLOW_PALBIN}'." unless app_const_rule_ok?

        role_ids = VALID_ROLES.values.map { |v| @entity.send(v) }
        EdiOutRepo.new.flow_has_matching_rule(AppConst::EDI_FLOW_PALBIN,
                                              depot_ids: Array(@entity.depot_id),
                                              party_role_ids: role_ids)
      end

      def app_const_rule_ok?
        AppConst::EDI_OUT_RULES_TEMPLATE[AppConst::EDI_FLOW_PALBIN][:depot] == DEPOT_VALID &&
          AppConst::EDI_OUT_RULES_TEMPLATE[AppConst::EDI_FLOW_PALBIN][:roles] == VALID_ROLES.keys
      end
    end
  end
end
