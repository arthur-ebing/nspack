# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class EcertTrackingUnit < BaseService
      attr_reader :task, :entity
      def initialize(task, ecert_tracking_unit_id = nil)
        @task = task
        @repo = EcertRepo.new
        @id = ecert_tracking_unit_id
        @entity = @id ? @repo.find_ecert_tracking_unit(@id) : nil
      end

      CHECKS = {
        delete: :delete_check
      }.freeze

      def call
        return failed_response 'Ecert Tracking Unit record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def delete_check
        all_ok
      end
    end
  end
end
