# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class PresortGrowerGradingPool < BaseService
      attr_reader :task, :entity
      def initialize(task, presort_grower_grading_pool_id = nil)
        @task = task
        @repo = PresortGrowerGradingRepo.new
        @id = presort_grower_grading_pool_id
        @entity = @id ? @repo.find_presort_grower_grading_pool(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        complete_pool: :complete_check,
        un_complete_pool: :un_complete_check,
        import_maf_data: :import_maf_data_check,
        refresh_pool: :refresh_pool_check
      }.freeze

      def call
        return failed_response 'Presort Grower Grading Pool record not found' unless @entity || task == :create

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

      def complete_check
        return failed_response 'PresortGrowerGradingPool has already been completed' if completed?

        # ungraded_bins = @repo.select_values(:presort_grower_grading_bins, :id, presort_grower_grading_pool_id: @id, graded: false)
        # return failed_response 'Some bins on the pool are not yet graded.' unless ungraded_bins.empty?

        all_ok
      end

      def un_complete_check
        return failed_response 'PresortGrowerGradingPool has not been completed' unless completed?

        all_ok
      end

      def import_maf_data_check
        return failed_response 'PresortGrowerGradingPool has already been completed' if completed?

        all_ok
      end

      def refresh_pool_check
        return failed_response 'PresortGrowerGradingPool has already been completed' if completed?

        all_ok
      end

      def completed?
        @entity.completed
      end
    end
  end
end
