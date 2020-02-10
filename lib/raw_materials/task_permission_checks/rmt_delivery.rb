# frozen_string_literal: true

module RawMaterialsApp
  module TaskPermissionCheck
    class RmtDelivery < BaseService
      attr_reader :task, :entity
      def initialize(task, rmt_delivery_id = nil)
        @task = task
        @repo = RmtDeliveryRepo.new
        @id = rmt_delivery_id
        @entity = @id ? @repo.find_rmt_delivery(@id) : nil
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
        return failed_response 'Record not found' unless @entity || task == :create

        check = CHECKS[task]
        raise ArgumentError, "Task \"#{task}\" is unknown for #{self.class}" if check.nil?

        send(check)
      end

      private

      def create_check
        all_ok
      end

      def edit_check
        return failed_response 'Bins on this delivery have been tipped' if bins_tipped?

        all_ok
      end

      def delete_check
        all_ok
      end

      def bins_tipped?
        @repo.exists?(:rmt_bins, rmt_delivery_id: @id, bin_tipped: true)
      end
    end
  end
end
