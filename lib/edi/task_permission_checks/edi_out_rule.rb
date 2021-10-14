# frozen_string_literal: true

module EdiApp
  module TaskPermissionCheck
    class EdiOutRule < BaseService
      attr_reader :task, :entity

      def initialize(task, edi_out_rule_id = nil)
        @task = task
        @repo = EdiOutRepo.new
        @id = edi_out_rule_id
        @entity = @id ? @repo.find_edi_out_rule(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'EDI Out Rule record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'EdiOutRule has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'EdiOutRule has been completed' if completed?

        all_ok
      end
    end
  end
end
