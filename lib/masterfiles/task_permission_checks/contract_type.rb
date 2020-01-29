# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class ContractType < BaseService
      attr_reader :task, :entity
      def initialize(task, contract_type_id = nil)
        @task = task
        @repo = HumanResourcesRepo.new
        @id = contract_type_id
        @entity = @id ? @repo.find_contract_type(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Contract Type record not found' unless @entity || task == :create

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
