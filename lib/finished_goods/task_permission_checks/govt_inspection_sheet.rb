# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class GovtInspectionSheet < BaseService
      attr_reader :task, :entity
      def initialize(task, govt_inspection_sheet_id = nil)
        @task = task
        @repo = GovtInspectionRepo.new
        @id = govt_inspection_sheet_id
        @entity = @id ? @repo.find_govt_inspection_sheet(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        capture: :capture_check,
        complete: :complete_check,
        approve: :approve_check,
        reopen: :reopen_check
      }.freeze

      def call
        return failed_response 'Govt Inspection Sheet record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'GovtInspectionSheet inspection has been completed' if inspected?

        all_ok
      end

      def delete_check
        return failed_response 'GovtInspectionSheet has been completed' if completed?

        all_ok
      end

      def complete_check
        return failed_response 'GovtInspectionSheet has already been completed' if completed?

        all_ok
      end

      def reopen_check
        return failed_response 'GovtInspectionSheet is not completed' unless completed?

        all_ok
      end

      def capture_check
        return failed_response 'GovtInspectionSheet has already been inspected' if inspected?

        all_ok
      end

      def completed?
        @entity&.completed
      end

      def inspected?
        @entity&.inspected
      end

      def approved?
        @entity&.approved
      end
    end
  end
end
