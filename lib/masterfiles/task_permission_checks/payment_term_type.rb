# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class PaymentTermType < BaseService
      attr_reader :task, :entity
      def initialize(task, payment_term_type_id = nil)
        @task = task
        @repo = FinanceRepo.new
        @id = payment_term_type_id
        @entity = @id ? @repo.find_payment_term_type(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Payment Term Type record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        all_ok
      end

      def delete_check
        all_ok
      end
    end
  end
end
