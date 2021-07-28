# frozen_string_literal: true

module FinishedGoodsApp
  module TaskPermissionCheck
    class PalletHoldover < BaseService
      attr_reader :task, :entity
      def initialize(task, pallet_holdover_id = nil)
        @task = task
        @repo = PalletHoldoverRepo.new
        @id = pallet_holdover_id
        @entity = @id ? @repo.find_pallet_holdover(@id) : nil
      end

      CHECKS = {
        create: :create_check,
        edit: :edit_check,
        delete: :delete_check,
        complete: :complete_check
      }.freeze

      def call
        return failed_response 'Pallet Holdover record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'PalletHoldover has been completed' if completed?

        all_ok
      end

      def delete_check
        return failed_response 'PalletHoldover has been completed' if completed?

        all_ok
      end

      def complete_check
        return failed_response 'PalletHoldover has already been completed' if completed?

        all_ok
      end

      def completed?
        @entity.completed
      end
    end
  end
end
