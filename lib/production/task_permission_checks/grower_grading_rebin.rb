# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class GrowerGradingRebin < BaseService
      attr_reader :task, :entity
      def initialize(task, grower_grading_rebin_id = nil)
        @task = task
        @repo = GrowerGradingRepo.new
        @id = grower_grading_rebin_id
        @entity = @id ? @repo.find_grower_grading_rebin(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        complete_rebin: :complete_rebin_check
      }.freeze

      def call
        return failed_response 'Grower Grading Rebin record not found' unless @entity || task == :create

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

      def complete_rebin_check
        changes_made = @repo.select_values(:grower_grading_rebins, :changes_made, id: @id)
        return failed_response 'Grading Rebin changes not yet set.' unless changes_made.nil_or_empty?

        all_ok
      end
    end
  end
end
