# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class PresortGrowerGradingBin < BaseService
      attr_reader :task, :entity
      def initialize(task, presort_grower_grading_bin_id = nil)
        @task = task
        @repo = PresortGrowerGradingRepo.new
        @id = presort_grower_grading_bin_id
        @entity = @id ? @repo.find_presort_grower_grading_bin(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Presort Grower Grading Bin record not found' unless @entity || task == :create

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
