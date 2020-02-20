# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class Shift < BaseService
      attr_reader :task, :entity
      def initialize(task, shift_id = nil)
        @task = task
        @repo = MasterfilesApp::HumanResourcesRepo.new
        @id = shift_id
        @entity = @id ? @repo.find_shift(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
        # complete: :complete_check,
        # approve: :approve_check,
        # reopen: :reopen_check
      }.freeze

      def call
        return failed_response 'Shift record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        # return failed_response 'Shift has been completed' if completed?

        all_ok
      end

      def delete_check
        # return failed_response 'Shift has been completed' if completed?

        all_ok
      end

      # def completed?
      #   @entity.completed
      # end

      # def approved?
      #   @entity.approved
      # end
    end
  end
end
