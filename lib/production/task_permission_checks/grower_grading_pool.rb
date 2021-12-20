# frozen_string_literal: true

module ProductionApp
  module TaskPermissionCheck
    class GrowerGradingPool < BaseService
      attr_reader :task, :entity
      def initialize(task, grower_grading_pool_id = nil)
        @task = task
        @repo = GrowerGradingRepo.new
        @id = grower_grading_pool_id
        @entity = @id ? @repo.find_grower_grading_pool(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        complete_pool: :complete_pool_check
      }.freeze

      def call
        return failed_response 'Grower Grading Pool record not found' unless @entity || task == :create

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

      def complete_pool_check
        grading_carton_ids = @repo.select_values(:grower_grading_cartons, :id, grower_grading_pool_id: @id, completed: false)
        grading_rebin_ids = @repo.select_values(:grower_grading_rebins, :id, grower_grading_pool_id: @id, completed: false)
        return failed_response 'Some cartons on the pool are not yet graded.' unless grading_carton_ids.empty? && grading_rebin_ids.empty?

        all_ok
      end
    end
  end
end
