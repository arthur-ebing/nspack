# frozen_string_literal: true

module MasterfilesApp
  module TaskPermissionCheck
    class OrchardTestType < BaseService
      attr_reader :task, :entity
      def initialize(task, orchard_test_type_id = nil)
        @task = task
        @repo = OrchardTestRepo.new
        @id = orchard_test_type_id
        @entity = @id ? @repo.find_orchard_test_type(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Orchard Test Type record not found' unless @entity || task == :create

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
