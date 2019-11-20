# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class ReworksRun < BaseService
      attr_reader :task, :entity
      def initialize(task, reworks_run_id = nil)
        @task = task
        @repo = ReworksRepo.new
        @id = reworks_run_id
        @entity = @id ? @repo.find_reworks_run(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Reworks Run record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'ReworksRun has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'ReworksRun has been completed' if completed?

        all_ok
      end
    end
  end
end
